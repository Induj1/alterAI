import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../backend/application/backend_config_controller.dart';
import '../../profile/application/profile_provider.dart';
import '../../voice/data/native_audio_capture.dart';
import '../../voice/data/sarvam_live_voice_client.dart';
import '../../voice/data/voice_runtime_api_client.dart';
import 'agent_tools.dart';
import 'persistent_intelligence_store.dart';

enum AgentRole { user, assistant, tool }

class AgentMessage {
  AgentMessage(this.role, this.text, {this.pending = false});
  final AgentRole role;
  String text;
  bool pending;
}

class AgentState {
  const AgentState({
    this.messages = const [],
    this.isThinking = false,
    this.isListening = false,
    this.isSarvamRecording = false,
    this.partial = '',
    this.error = '',
    this.liveVoiceStatus = '',
  });

  final List<AgentMessage> messages;
  final bool isThinking;
  final bool isListening;
  final bool isSarvamRecording;
  final String partial;
  final String error;
  final String liveVoiceStatus;

  AgentState copyWith({
    List<AgentMessage>? messages,
    bool? isThinking,
    bool? isListening,
    bool? isSarvamRecording,
    String? partial,
    String? error,
    String? liveVoiceStatus,
  }) => AgentState(
    messages: messages ?? this.messages,
    isThinking: isThinking ?? this.isThinking,
    isListening: isListening ?? this.isListening,
    isSarvamRecording: isSarvamRecording ?? this.isSarvamRecording,
    partial: partial ?? this.partial,
    error: error ?? this.error,
    liveVoiceStatus: liveVoiceStatus ?? this.liveVoiceStatus,
  );
}

final agentControllerProvider = NotifierProvider<AgentController, AgentState>(
  AgentController.new,
);

class AgentController extends Notifier<AgentState> {
  final _api = <Map<String, dynamic>>[];
  final _tts = FlutterTts();
  final _audio = const NativeAudioBridge();
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;

  @override
  AgentState build() {
    _api.add({'role': 'system', 'content': _systemPrompt()});
    ref.onDispose(() {
      _tts.stop();
      _audio.cancelRecording();
      _audio.stopPlayback();
      _stt.cancel();
    });
    return AgentState(
      messages: [
        AgentMessage(
          AgentRole.assistant,
          'Hi, I\'m ALTER. Talk to me — ask me to check if something\'s safe, '
          'plan your day, weigh a decision, message someone, or look something up.',
        ),
      ],
    );
  }

  // --- Voice in ---
  Future<void> toggleListening() async {
    if (state.isListening) {
      await _stt.stop();
      state = state.copyWith(isListening: false);
      return;
    }
    _sttReady =
        _sttReady ||
        await _stt.initialize(
          onError: (_) {},
          onStatus: (s) {
            if (s == 'done' || s == 'notListening') {
              state = state.copyWith(isListening: false);
            }
          },
        );
    if (!_sttReady) {
      state = state.copyWith(
        error: 'Speech recognition unavailable. Type instead.',
      );
      return;
    }
    await _tts.stop();
    state = state.copyWith(isListening: true, partial: '', error: '');
    await _stt.listen(
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      ),
      onResult: (r) {
        state = state.copyWith(partial: r.recognizedWords);
        if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
          state = state.copyWith(isListening: false, partial: '');
          send(r.recognizedWords);
        }
      },
    );
  }

  // --- The conversational tool-calling loop ---
  Future<void> send(String text) async {
    final input = text.trim();
    if (input.isEmpty || state.isThinking) return;

    final openai = ref.read(openAIServiceProvider);
    if (openai == null) {
      _push(AgentRole.user, input);
      await ref
          .read(persistentIntelligenceStoreProvider.notifier)
          .addMemory(
            source: 'agent_chat',
            title: input,
            summary: 'User message sent to ALTER.',
          );
      state = state.copyWith(isThinking: true, error: '');
      final backendReply = await _runBackendRuntime(input);
      if (backendReply != null) {
        _push(AgentRole.assistant, backendReply);
        state = state.copyWith(isThinking: false);
        await _speak(backendReply);
        return;
      }
      state = state.copyWith(isThinking: false);
      _push(
        AgentRole.assistant,
        'Connect the backend gateway or sign in with AI access to help.',
      );
      return;
    }

    _push(AgentRole.user, input);
    await ref
        .read(persistentIntelligenceStoreProvider.notifier)
        .addMemory(
          source: 'agent_chat',
          title: input,
          summary: 'User message sent to ALTER.',
        );
    _api.add({'role': 'user', 'content': input});
    state = state.copyWith(isThinking: true, error: '');

    try {
      for (var i = 0; i < 6; i++) {
        final resp = await openai.chatWithTools(
          messages: List<Map<String, dynamic>>.from(_api),
          tools: kAgentTools,
        );
        final content = (resp['content'] ?? '').toString();
        final toolCalls = resp['tool_calls'];

        if (toolCalls is List && toolCalls.isNotEmpty) {
          _api.add({
            'role': 'assistant',
            'content': content.isEmpty ? null : content,
            'tool_calls': toolCalls,
          });
          for (final tc in toolCalls) {
            final m = Map<String, dynamic>.from(tc as Map);
            final id = m['id']?.toString() ?? '';
            final fn = Map<String, dynamic>.from(m['function'] as Map);
            final name = fn['name']?.toString() ?? '';
            Map<String, dynamic> args;
            try {
              args =
                  jsonDecode((fn['arguments'] ?? '{}').toString())
                      as Map<String, dynamic>;
            } catch (_) {
              args = {};
            }
            final toolMsg = AgentMessage(
              AgentRole.tool,
              agentToolLabel(name),
              pending: true,
            );
            _appendMessage(toolMsg);
            final result = await executeAgentTool(ref, name, args);
            toolMsg.text = result;
            toolMsg.pending = false;
            _bump();
            _api.add({'role': 'tool', 'tool_call_id': id, 'content': result});
          }
          continue; // let the model react to the tool results
        }

        // Final spoken answer.
        _api.add({'role': 'assistant', 'content': content});
        _push(AgentRole.assistant, content);
        state = state.copyWith(isThinking: false);
        await _speak(content);
        return;
      }
      state = state.copyWith(isThinking: false);
    } catch (e) {
      state = state.copyWith(
        isThinking: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      _push(AgentRole.assistant, 'Something went wrong: ${state.error}');
    }
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    final spokeWithSarvam = await _speakWithSarvam(text);
    if (spokeWithSarvam) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.52);
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<bool> _speakWithSarvam(String text) async {
    try {
      final config = await ref.read(backendConfigProvider.future);
      if (!config.hasGateway) return false;
      final client = SarvamLiveVoiceClient(baseUrl: config.gatewayUrl);
      final tts = await client.synthesize(
        text: text,
        targetLanguageCode: 'en-IN',
      );
      client.close();
      if (tts.audioBase64.isEmpty || tts.fallback) return false;
      final playback = await _audio.playAudioBase64(
        audioBase64: tts.audioBase64,
        filename: 'alter_sarvam_tts.wav',
      );
      return playback.ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleSarvamLiveVoice() async {
    if (state.isThinking) return;
    if (!state.isSarvamRecording) {
      await _tts.stop();
      await _audio.stopPlayback();
      final started = await _audio.startRecording();
      state = state.copyWith(
        isSarvamRecording: started.ok,
        liveVoiceStatus: started.message,
        error: started.ok ? '' : started.message,
      );
      return;
    }

    state = state.copyWith(
      isSarvamRecording: false,
      liveVoiceStatus: 'Transcribing with backend speech stack...',
    );
    final captured = await _audio.stopRecording();
    if (!captured.ok || captured.audioBase64.isEmpty) {
      state = state.copyWith(error: captured.message, liveVoiceStatus: '');
      return;
    }

    try {
      final config = await ref.read(backendConfigProvider.future);
      if (!config.hasGateway) {
        state = state.copyWith(
          error: 'Save a backend gateway URL before using Sarvam live voice.',
          liveVoiceStatus: '',
        );
        return;
      }
      final client = SarvamLiveVoiceClient(baseUrl: config.gatewayUrl);
      final stt = await client.transcribe(captured);
      client.close();
      if (stt.transcript.trim().isEmpty) {
        state = state.copyWith(
          error: stt.error.isNotEmpty
              ? stt.error
              : 'Speech backend returned no transcript.',
          liveVoiceStatus: '',
        );
        return;
      }
      state = state.copyWith(
        liveVoiceStatus: 'Transcribed by ${stt.provider}: ${stt.transcript}',
      );
      await ref
          .read(persistentIntelligenceStoreProvider.notifier)
          .addMemory(
            source: 'sarvam_voice',
            title: stt.transcript,
            summary: 'Live voice transcript from ${stt.provider}.',
            metadata: {'language_code': stt.languageCode},
          );
      await send(stt.transcript);
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
        liveVoiceStatus: '',
      );
    }
  }

  void stopSpeaking() {
    _tts.stop();
    _audio.stopPlayback();
  }

  Future<String?> _runBackendRuntime(String input) async {
    final config = await ref.read(backendConfigProvider.future);
    if (!config.hasGateway) return null;
    final client = VoiceRuntimeApiClient(baseUrl: config.gatewayUrl);
    try {
      final result = await client.run(
        transcript: input,
        locale: 'en-US',
        profile: ref.read(userProfileProvider).asData?.value,
      );
      client.close();
      return result.displayResponse.isNotEmpty
          ? result.displayResponse
          : result.spokenResponse;
    } catch (error) {
      client.close();
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  void _push(AgentRole role, String text) =>
      _appendMessage(AgentMessage(role, text));

  void _appendMessage(AgentMessage m) {
    state = state.copyWith(messages: [...state.messages, m]);
  }

  // Force a state emit after mutating a message in place.
  void _bump() => state = state.copyWith(messages: [...state.messages]);

  String _systemPrompt() {
    final profile = ref.read(userProfileProvider).asData?.value;
    final who = profile == null || profile.displayName.isEmpty
        ? ''
        : 'You are speaking with ${profile.displayName}'
              '${profile.role.isNotEmpty ? ', a ${profile.role}' : ''}. ';
    return 'You are ALTER, a proactive voice assistant living on the user\'s '
        'iQOO phone. ${who}You converse naturally and briefly — your replies are '
        'spoken aloud, so keep them short, warm, and clear. '
        'When the user asks you to DO something, USE A TOOL rather than just '
        'describing it. You can: check safety of a message/link/payment, plan '
        'the day, weigh a decision, convene a 5-voice council, call a number, '
        'send a WhatsApp/SMS, open a link, search the web, add a calendar '
        'event, open apps/settings, read visible screen text, click visible '
        'non-sensitive UI text, type into focused fields, scroll, and press '
        'Back/Home/Recents/Notifications. Before clicking in another app, read '
        'the screen first and choose visible labels rather than guessing. Device '
        'actions open or control only permissioned Android surfaces — after '
        'calling one, tell them what happened and what still needs their final tap. '
        'Never claim you actually sent, paid, called, or installed anything; you '
        'prepare it and the user confirms. Never directly click Send, Pay, '
        'Confirm, Install, Approve, Delete, or Allow; route that through OpenClaw '
        'with queue_openclaw_action or ask the user to tap it. If you need a phone number or detail '
        'you don\'t have, ask for it. After a tool returns, summarize the result '
        'in one or two spoken sentences.';
  }
}
