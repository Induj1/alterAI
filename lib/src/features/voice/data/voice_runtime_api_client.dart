import 'dart:convert';

import 'package:http/http.dart' as http;

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
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/v1/voice/action-runtime'),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, Object>{
            'transcript': transcript,
            'locale': locale,
            'device_surface': 'phone',
            'user_profile': const <String, Object>{
              'name': 'ALTER Operator',
              'current_role': 'Student founder',
              'career_stage': 'student founder',
              'industry': 'AI',
              'current_network_size': 180,
              'risk_tolerance': 0.72,
              'weekly_learning_hours': 12,
            },
            'skills': const <String>[
              'AI agents',
              'Flutter',
              'FastAPI',
              'Product strategy',
              'Founder storytelling',
            ],
            'goals': const <String>[
              'Build ALTER into a real startup',
              'Validate strong user demand',
              'Create a trusted personal AI operating system',
            ],
            'interests': const <String>[
              'AI assistants',
              'future decisions',
              'startup networks',
            ],
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
