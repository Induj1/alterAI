import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/application/profile_provider.dart';
import '../../profile/domain/user_profile.dart';
import '../data/voice_runtime_api_client.dart';

final voiceRuntimeApiClientProvider = Provider<VoiceRuntimeApiClient>((ref) {
  final client = VoiceRuntimeApiClient(
    baseUrl: const String.fromEnvironment(
      'ALTER_API_GATEWAY_URL',
      defaultValue: 'http://localhost:8060',
    ),
  );
  ref.onDispose(client.close);
  return client;
});

final voiceRuntimeControllerProvider =
    NotifierProvider<VoiceRuntimeController, VoiceRuntimeState>(
  VoiceRuntimeController.new,
);

class VoiceRuntimeController extends Notifier<VoiceRuntimeState> {
  @override
  VoiceRuntimeState build() => const VoiceRuntimeState();

  Future<void> run({
    required String transcript,
    required String locale,
  }) async {
    final trimmed = transcript.trim();
    if (trimmed.length < 3) {
      state = state.copyWith(errorMessage: 'Say or type a command for ALTER.');
      return;
    }
    state = state.copyWith(isRunning: true, errorMessage: '', clearResult: true);

    try {
      final openai = ref.read(openAIServiceProvider);
      if (openai != null) {
        final profile = ref.read(userProfileProvider).asData?.value;
        final result = await _runDirect(trimmed, locale, profile);
        state = state.copyWith(isRunning: false, result: result);
      } else {
        final result = await ref
            .read(voiceRuntimeApiClientProvider)
            .run(transcript: trimmed, locale: locale);
        state = state.copyWith(isRunning: false, result: result);
      }
    } catch (error) {
      final msg = error.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isRunning: false, errorMessage: msg);
    }
  }

  Future<VoiceRuntimeResult> _runDirect(
    String transcript,
    String locale,
    UserProfile? profile,
  ) async {
    final openai = ref.read(openAIServiceProvider)!;
    final systemPrompt = _buildSystemPrompt(profile, locale);

    final raw = await openai.chat(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': transcript},
      ],
      temperature: 0.72,
      maxTokens: 1400,
    );

    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```(?:json)?\s*\n?'), '')
          .replaceFirst(RegExp(r'\n?\s*```$'), '');
    }

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    final result = VoiceRuntimeResult.fromJson(json);

    // Store conversation — non-fatal if it fails
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('conversations').insert([
          {
            'user_id': userId,
            'role': 'user',
            'content': transcript,
            'intent': result.inferredIntent,
          },
          {
            'user_id': userId,
            'role': 'assistant',
            'content': result.spokenResponse,
            'intent': result.inferredIntent,
          },
        ]);
      }
    } catch (_) {}

    return result;
  }

  String _buildSystemPrompt(UserProfile? profile, String locale) {
    final name = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'the user';
    final role = profile?.role.isNotEmpty == true ? profile!.role : 'professional';
    final skills = profile?.skills.isNotEmpty == true
        ? profile!.skills.join(', ')
        : 'diverse skills';
    final goals = profile?.goals.isNotEmpty == true
        ? profile!.goals.join('; ')
        : 'professional growth';

    return '''You are ALTER, an AI Future OS for $name. You are their strategic intelligence layer — think Siri + Google Assistant + a McKinsey partner.
User profile: role=$role | skills=$skills | goals=$goals | locale=$locale

Analyze the voice command and respond ONLY with valid JSON (no markdown fences, no extra text):
{
  "normalized_text": "cleaned, improved version of the transcript",
  "wake_word_detected": true,
  "inferred_intent": "snake_case_intent",
  "intent_confidence": 0.0-1.0,
  "spoken_response": "1-2 sentences spoken aloud — direct, personalized, actionable",
  "display_response": "2-4 sentences with context and strategic reasoning",
  "action_graph": ["step 1", "step 2", "step 3"],
  "experiment_plan": {
    "action": "specific 24-48h action",
    "why_it_matters": "why this matters for ${profile?.displayName ?? name}\'s goals",
    "deadline": "48 hours",
    "success_metric": "measurable outcome"
  },
  "next_actions": ["action 1", "action 2", "action 3"],
  "follow_up_questions": ["question 1", "question 2"],
  "signals": [
    {"title": "Memory", "status": "ok", "summary": "Personal context loaded", "latency_ms": 38},
    {"title": "Reasoning", "status": "ok", "summary": "Strategic analysis complete", "latency_ms": 195},
    {"title": "Profile", "status": "ok", "summary": "User profile matched", "latency_ms": 12}
  ]
}''';
  }
}

class VoiceRuntimeState {
  const VoiceRuntimeState({
    this.isRunning = false,
    this.result,
    this.errorMessage = '',
  });

  final bool isRunning;
  final VoiceRuntimeResult? result;
  final String errorMessage;

  VoiceRuntimeState copyWith({
    bool? isRunning,
    VoiceRuntimeResult? result,
    String? errorMessage,
    bool clearResult = false,
  }) {
    return VoiceRuntimeState(
      isRunning: isRunning ?? this.isRunning,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
