import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../profile/domain/user_profile.dart';

const _voiceRuntimeTimeout = Duration(seconds: 20);

class VoiceRuntimeApiClient {
  VoiceRuntimeApiClient({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<VoiceRuntimeResult> run({
    required String transcript,
    required String locale,
    UserProfile? profile,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/v1/voice/action-runtime'),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, Object>{
            'transcript': transcript,
            'locale': locale,
            'device_surface': 'phone',
            'user_profile': _profilePayload(profile),
            'skills': _cleanList(profile?.skills),
            'goals': _cleanList(profile?.goals),
            'interests': _cleanList(profile?.interests),
          }),
        )
        .timeout(_voiceRuntimeTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VoiceRuntimeApiException(
        'Voice runtime returned ${response.statusCode}: ${response.body}',
      );
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const VoiceRuntimeApiException(
        'Voice runtime returned invalid JSON.',
      );
    }
    return VoiceRuntimeResult.fromJson(body);
  }

  void close() => _client.close();
}

class VoiceRuntimeApiException implements Exception {
  const VoiceRuntimeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VoiceRuntimeResult {
  const VoiceRuntimeResult({
    required this.normalizedText,
    required this.wakeWordDetected,
    required this.inferredIntent,
    required this.intentConfidence,
    required this.spokenResponse,
    required this.displayResponse,
    required this.aiProvider,
    required this.sourceLanguageCode,
    required this.responseLanguageCode,
    required this.languageDisplayName,
    required this.actionGraph,
    required this.experimentPlan,
    required this.nextActions,
    required this.followUpQuestions,
    required this.signals,
  });

  factory VoiceRuntimeResult.fromJson(Map<String, dynamic> json) {
    return VoiceRuntimeResult(
      normalizedText: _string(json['normalized_text']),
      wakeWordDetected: json['wake_word_detected'] == true,
      inferredIntent: _string(json['inferred_intent'], fallback: 'unknown'),
      intentConfidence: _double(json['intent_confidence']),
      spokenResponse: _string(json['spoken_response']),
      displayResponse: _string(json['display_response']),
      aiProvider: _string(json['ai_provider'], fallback: 'alter-local'),
      sourceLanguageCode: _string(
        json['source_language_code'],
        fallback: 'auto',
      ),
      responseLanguageCode: _string(
        json['response_language_code'],
        fallback: 'en-IN',
      ),
      languageDisplayName: _string(
        json['language_display_name'],
        fallback: 'English',
      ),
      actionGraph: _parseStringList(json['action_graph']),
      experimentPlan: json['experiment_plan'] is Map<String, dynamic>
          ? VoiceExperimentPlan.fromJson(
              json['experiment_plan'] as Map<String, dynamic>,
            )
          : null,
      nextActions: _parseStringList(json['next_actions']),
      followUpQuestions: _parseStringList(json['follow_up_questions']),
      signals: _parseSignals(json['signals']),
    );
  }

  final String normalizedText;
  final bool wakeWordDetected;
  final String inferredIntent;
  final double intentConfidence;
  final String spokenResponse;
  final String displayResponse;
  final String aiProvider;
  final String sourceLanguageCode;
  final String responseLanguageCode;
  final String languageDisplayName;
  final List<String> actionGraph;
  final VoiceExperimentPlan? experimentPlan;
  final List<String> nextActions;
  final List<String> followUpQuestions;
  final List<VoiceRuntimeSignal> signals;
}

class VoiceExperimentPlan {
  const VoiceExperimentPlan({
    required this.action,
    required this.whyItMatters,
    required this.deadline,
    required this.successMetric,
  });

  factory VoiceExperimentPlan.fromJson(Map<String, dynamic> json) {
    return VoiceExperimentPlan(
      action: _string(json['action']),
      whyItMatters: _string(json['why_it_matters']),
      deadline: _string(json['deadline']),
      successMetric: _string(json['success_metric']),
    );
  }

  final String action;
  final String whyItMatters;
  final String deadline;
  final String successMetric;
}

class VoiceRuntimeSignal {
  const VoiceRuntimeSignal({
    required this.title,
    required this.status,
    required this.summary,
    required this.latencyMs,
  });

  factory VoiceRuntimeSignal.fromJson(Map<String, dynamic> json) {
    return VoiceRuntimeSignal(
      title: _string(json['title']),
      status: _string(json['status'], fallback: 'unknown'),
      summary: _string(json['summary']),
      latencyMs: json['latency_ms'] is num
          ? (json['latency_ms'] as num).round()
          : null,
    );
  }

  final String title;
  final String status;
  final String summary;
  final int? latencyMs;

  bool get isHealthy => status == 'ok';
}

List<String> _parseStringList(Object? raw) {
  if (raw is! List<dynamic>) {
    return const <String>[];
  }
  return raw.whereType<String>().toList(growable: false);
}

List<VoiceRuntimeSignal> _parseSignals(Object? raw) {
  if (raw is! List<dynamic>) {
    return const <VoiceRuntimeSignal>[];
  }
  return raw
      .whereType<Map<String, dynamic>>()
      .map(VoiceRuntimeSignal.fromJson)
      .toList(growable: false);
}

double _double(Object? raw) {
  return raw is num ? raw.toDouble() : 0;
}

String _string(Object? raw, {String fallback = ''}) {
  return raw is String && raw.isNotEmpty ? raw : fallback;
}

Map<String, Object> _profilePayload(UserProfile? profile) {
  return <String, Object>{
    'name': _string(profile?.displayName),
    'current_role': _string(profile?.role),
    'career_stage': _string(profile?.careerStage),
    'industry': _string(profile?.industry),
    'bio': _string(profile?.bio),
    'skills': _cleanList(profile?.skills),
    'goals': _cleanList(profile?.goals),
    'interests': _cleanList(profile?.interests),
  };
}

List<String> _cleanList(List<String>? values) {
  return values
          ?.map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false) ??
      const <String>[];
}
