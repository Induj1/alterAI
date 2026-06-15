import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../actions/action_runtime.dart';
import 'agent_tools.dart';

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
    this.partial = '',
    this.error = '',
  });

  final List<AgentMessage> messages;
  final bool isThinking;
  final bool isListening;
  final String partial;
  final String error;

  AgentState copyWith({
    List<AgentMessage>? messages,
    bool? isThinking,
    bool? isListening,
    String? partial,
    String? error,
  }) => AgentState(
    messages: messages ?? this.messages,
    isThinking: isThinking ?? this.isThinking,
    isListening: isListening ?? this.isListening,
    partial: partial ?? this.partial,
    error: error ?? this.error,
  );
}

final agentControllerProvider = NotifierProvider<AgentController, AgentState>(
  AgentController.new,
);

class AgentController extends Notifier<AgentState> {
  final _api = <Map<String, dynamic>>[];
  final _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;

  /// When true, the controller does not speak replies itself — the caller
  /// (e.g. the Voice screen) handles TTS, typically with a multilingual voice.
  bool _muteSpeech = false;
  void setMuteSpeech(bool value) => _muteSpeech = value;

  @override
  AgentState build() {
    _api.addAll(ActionRuntime.freshApiMessages(ref));
    ref.onDispose(() {
      _tts.stop();
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
  Future<void> send(String text, {bool deep = false}) async {
    final input = text.trim();
    if (input.isEmpty || state.isThinking) return;

    _push(AgentRole.user, input);
    state = state.copyWith(isThinking: true, error: '');

    try {
      final result = await ActionRuntime.runTurn(
        ref: ref,
        apiMessages: _api,
        userInput: input,
        deep: deep,
        onToolStart: (name) {
          final toolMsg = AgentMessage(
            AgentRole.tool,
            agentToolLabel(name),
            pending: true,
          );
          _appendMessage(toolMsg);
        },
        onToolComplete: (name, toolResult) {
          for (final m in state.messages.reversed) {
            if (m.role == AgentRole.tool && m.pending) {
              m.text = toolResult;
              m.pending = false;
              break;
            }
          }
          _bump();
        },
      );
      _push(AgentRole.assistant, result.reply);
      state = state.copyWith(isThinking: false);
      await _speak(result.reply);
    } catch (e) {
      final msg = UserFacingError.from(e).message;
      state = state.copyWith(isThinking: false, error: msg);
      _push(AgentRole.assistant, msg);
    }
  }

  Future<void> _speak(String text) async {
    if (_muteSpeech) return;
    if (text.trim().isEmpty) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.52);
      await _tts.speak(text);
    } catch (_) {}
  }

  void stopSpeaking() => _tts.stop();

  void _push(AgentRole role, String text) =>
      _appendMessage(AgentMessage(role, text));

  void _appendMessage(AgentMessage m) {
    state = state.copyWith(messages: [...state.messages, m]);
  }

  // Force a state emit after mutating a message in place.
  void _bump() => state = state.copyWith(messages: [...state.messages]);
}
