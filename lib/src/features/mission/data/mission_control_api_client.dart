import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/mission_control_models.dart';

class MissionControlApiClient {
  MissionControlApiClient({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<MissionControlSnapshot> loadSnapshot(
    MissionControlSnapshot fallback,
  ) async {
    final health = await _getJson('/v1/system/health');
    final briefing = await _postJson('/v1/mission/briefing', <String, Object>{
      'objective': fallback.activeObjective,
      'device_context': 'flutter-web',
    });

    final services = _parseServices(health['services']);
    final serviceMap = <String, _GatewayServiceHealth>{
      for (final service in services) service.name: service,
    };
    final okCount = services.where((service) => service.status == 'ok').length;
    final serviceCount = services.isEmpty ? 1 : services.length;
    final readiness = _bounded(okCount / serviceCount);
    final degraded = services
        .where((service) => service.status != 'ok')
        .map((service) => service.name)
        .toList(growable: false);
    final routeTargets = _parseStringList(briefing['route_targets']);
    final commandSummary = briefing['command_summary'] is String
        ? briefing['command_summary'] as String
        : fallback.activeObjective;

    return fallback.copyWith(
      activeObjective: commandSummary,
      readiness: readiness,
      backendStatus: health['status'] is String
          ? health['status'] as String
          : 'unknown',
      routeTargets: routeTargets,
      degradedServices: degraded,
      phoneModules: _hydrateModules(fallback.phoneModules, serviceMap),
      laptopModules: _hydrateModules(fallback.laptopModules, serviceMap),
      metrics: <MissionMetric>[
        MissionMetric(
          label: 'Backend',
          value: '${(readiness * 100).round()}%',
          detail: '$okCount of $serviceCount services are healthy.',
          moduleId: 'timelines',
        ),
        MissionMetric(
          label: 'Routes',
          value: '${routeTargets.length}',
          detail: 'Gateway route targets are available for mission execution.',
          moduleId: 'radar',
        ),
        MissionMetric(
          label: 'Services',
          value: '$okCount/$serviceCount',
          detail: degraded.isEmpty
              ? 'All ALTER services responded.'
              : 'Needs attention: ${degraded.join(', ')}.',
          moduleId: 'social',
        ),
        MissionMetric(
          label: 'Gateway',
          value: _statusLabel(health['status']),
          detail: 'Mission briefing is composed by the FastAPI edge.',
          moduleId: 'reputation',
        ),
      ],
      events: <MissionEvent>[
        MissionEvent(
          time: 'Live',
          title: 'Gateway mission briefing loaded',
          source: 'API',
          impact: 'Flutter is connected to FastAPI Mission Control.',
        ),
        MissionEvent(
          time: 'Live',
          title: '$okCount services responded to health checks',
          source: 'Backend',
          impact: degraded.isEmpty
              ? 'System is ready for end-to-end demos.'
              : 'Degraded services are visible in Mission Control.',
        ),
        ...fallback.events.take(2),
      ],
    );
  }

  Future<MissionDemoRun> runFutureOsDemo({required String objective}) async {
    final body = await _postJson('/v1/demo/future-os', <String, Object>{
      'objective': objective,
      'device_context': 'flutter-mission-control',
    });
    return MissionDemoRun.fromJson(body);
  }

  Future<IntelligenceDecisionReport> decide({
    required String question,
    Map<String, Object> userProfile = const <String, Object>{
      'name': 'ALTER Operator',
      'current_role': 'Student founder',
      'career_stage': 'student founder',
      'industry': 'AI',
      'current_salary': 70000,
      'current_network_size': 180,
      'risk_tolerance': 0.72,
      'weekly_learning_hours': 12,
    },
    List<String> skills = const <String>[
      'AI agents',
      'Flutter',
      'FastAPI',
      'Product strategy',
      'Founder storytelling',
    ],
    List<String> goals = const <String>[
      'Build ALTER into a real startup',
      'Validate strong user demand',
      'Earn reputation through follow-through',
    ],
    List<String> interests = const <String>[
      'AI agents',
      'future of work',
      'career decisions',
      'startup networks',
    ],
  }) async {
    final body = await _postJson('/v1/intelligence/decide', <String, Object>{
      'question': question,
      'user_profile': userProfile,
      'skills': skills,
      'goals': goals,
      'interests': interests,
      'decision_horizon_months': 36,
      'write_memory': true,
    });
    return IntelligenceDecisionReport.fromJson(body);
  }

  Future<OutcomeUpdateResult> recordOutcome({
    required IntelligenceDecisionReport report,
    required bool didIt,
    required String whatHappened,
    required String whatLearned,
    required String successMetricResult,
    required double outcomeScore,
  }) async {
    final body = await _postJson('/v1/intelligence/outcomes', <String, Object>{
      'user_id': report.userId,
      'decision_id': report.decisionId,
      'question': report.question,
      'experiment_plan': report.experimentPlan.toJson(),
      'did_it': didIt,
      'what_happened': whatHappened,
      'what_learned': whatLearned,
      'success_metric_result': successMetricResult,
      'outcome_score': outcomeScore,
    });
    return OutcomeUpdateResult.fromJson(body);
  }

  void close() => _client.close();

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'));
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object> payload,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: const <String, String>{'content-type': 'application/json'},
      body: jsonEncode(payload),
    );
    return _decodeJson(response);
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MissionControlApiException(
        'Mission Control API returned ${response.statusCode}: ${response.body}',
      );
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const MissionControlApiException(
        'Mission Control API returned invalid JSON.',
      );
    }
    return body;
  }
}

class MissionControlApiException implements Exception {
  const MissionControlApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _GatewayServiceHealth {
  const _GatewayServiceHealth({
    required this.name,
    required this.status,
    this.latencyMs,
  });

  factory _GatewayServiceHealth.fromJson(Map<String, dynamic> json) {
    return _GatewayServiceHealth(
      name: json['name'] is String ? json['name'] as String : 'unknown',
      status: json['status'] is String ? json['status'] as String : 'unknown',
      latencyMs: json['latency_ms'] is num
          ? (json['latency_ms'] as num).round()
          : null,
    );
  }

  final String name;
  final String status;
  final int? latencyMs;
}

List<_GatewayServiceHealth> _parseServices(Object? raw) {
  if (raw is! List<dynamic>) {
    return const <_GatewayServiceHealth>[];
  }
  return raw
      .whereType<Map<String, dynamic>>()
      .map(_GatewayServiceHealth.fromJson)
      .toList(growable: false);
}

List<String> _parseStringList(Object? raw) {
  if (raw is! List<dynamic>) {
    return const <String>[];
  }
  return raw.whereType<String>().toList(growable: false);
}

List<MissionModule> _hydrateModules(
  List<MissionModule> modules,
  Map<String, _GatewayServiceHealth> services,
) {
  return modules
      .map((module) {
        final service = services[_moduleToService[module.id]];
        if (service == null) {
          return module;
        }
        final isHealthy = service.status == 'ok';
        final latency = service.latencyMs == null
            ? ''
            : ' - ${service.latencyMs} ms';
        return module.copyWith(
          signal: isHealthy ? _bounded(module.signal + 0.03) : 0.42,
          health: isHealthy ? 0.96 : 0.34,
          status: isHealthy ? 'Live$latency' : 'Backend ${service.status}',
        );
      })
      .toList(growable: false);
}

String _statusLabel(Object? status) {
  if (status is! String || status.isEmpty) {
    return 'N/A';
  }
  return status.toUpperCase();
}

double _bounded(double value) {
  return value.clamp(0.0, 1.0).toDouble();
}

const _moduleToService = <String, String>{
  'voice': 'voice_gateway',
  'camera': 'alter_lens',
  'timelines': 'future_simulation',
  'council': 'clone_council',
  'radar': 'opportunity_engine',
  'social': 'social_graph',
  'reputation': 'reputation_engine',
};

class MissionDemoRun {
  const MissionDemoRun({
    required this.headline,
    required this.executiveSummary,
    required this.steps,
    required this.keyMetrics,
    required this.nextActions,
    required this.risks,
    required this.opportunities,
  });

  factory MissionDemoRun.fromJson(Map<String, dynamic> json) {
    return MissionDemoRun(
      headline: _string(json['headline']),
      executiveSummary: _string(json['executive_summary']),
      steps: _parseDemoSteps(json['steps']),
      keyMetrics: _parseStringMap(json['key_metrics']),
      nextActions: _parseStringList(json['next_actions']),
      risks: _parseStringList(json['risks']),
      opportunities: _parseStringList(json['opportunities']),
    );
  }

  final String headline;
  final String executiveSummary;
  final List<MissionDemoStep> steps;
  final Map<String, String> keyMetrics;
  final List<String> nextActions;
  final List<String> risks;
  final List<String> opportunities;
}

class MissionDemoStep {
  const MissionDemoStep({
    required this.name,
    required this.title,
    required this.status,
    required this.summary,
    required this.latencyMs,
  });

  factory MissionDemoStep.fromJson(Map<String, dynamic> json) {
    return MissionDemoStep(
      name: _string(json['name']),
      title: _string(json['title']),
      status: _string(json['status'], fallback: 'unknown'),
      summary: _string(json['summary']),
      latencyMs: json['latency_ms'] is num
          ? (json['latency_ms'] as num).round()
          : null,
    );
  }

  final String name;
  final String title;
  final String status;
  final String summary;
  final int? latencyMs;

  bool get isHealthy => status == 'ok';
}

List<MissionDemoStep> _parseDemoSteps(Object? raw) {
  if (raw is! List<dynamic>) {
    return const <MissionDemoStep>[];
  }
  return raw
      .whereType<Map<String, dynamic>>()
      .map(MissionDemoStep.fromJson)
      .toList(growable: false);
}

class IntelligenceDecisionReport {
  const IntelligenceDecisionReport({
    required this.decisionId,
    required this.userId,
    required this.question,
    required this.recommendation,
    required this.confidenceScore,
    required this.decisionSummary,
    required this.recommendedFuture,
    required this.experimentPlan,
    required this.futureOptions,
    required this.memoryContext,
    required this.opportunityMatches,
    required this.nextActions,
    required this.risks,
    required this.opportunities,
    required this.signals,
    required this.createdMemoryId,
  });

  factory IntelligenceDecisionReport.fromJson(Map<String, dynamic> json) {
    return IntelligenceDecisionReport(
      decisionId: _string(json['decision_id']),
      userId: _string(json['user_id']),
      question: _string(json['question']),
      recommendation: _string(json['recommendation']),
      confidenceScore: _double(json['confidence_score']),
      decisionSummary: _string(json['decision_summary']),
      recommendedFuture: _string(json['recommended_future']),
      experimentPlan: ExperimentPlan.fromJson(
        json['experiment_plan'] is Map<String, dynamic>
            ? json['experiment_plan'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
      futureOptions: _parseFutureOptions(json['future_options']),
      memoryContext: _parseStringList(json['memory_context']),
      opportunityMatches: _parseStringList(json['opportunity_matches']),
      nextActions: _parseStringList(json['next_actions']),
      risks: _parseStringList(json['risks']),
      opportunities: _parseStringList(json['opportunities']),
      signals: _parseIntelligenceSignals(json['signals']),
      createdMemoryId: _string(json['created_memory_id']),
    );
  }

  final String decisionId;
  final String userId;
  final String question;
  final String recommendation;
  final double confidenceScore;
  final String decisionSummary;
  final String recommendedFuture;
  final ExperimentPlan experimentPlan;
  final List<IntelligenceFutureOption> futureOptions;
  final List<String> memoryContext;
  final List<String> opportunityMatches;
  final List<String> nextActions;
  final List<String> risks;
  final List<String> opportunities;
  final List<IntelligenceSignal> signals;
  final String createdMemoryId;

  bool get memorySaved => createdMemoryId.isNotEmpty;
}

class ExperimentPlan {
  const ExperimentPlan({
    required this.experimentId,
    required this.action,
    required this.whyItMatters,
    required this.deadline,
    required this.successMetric,
  });

  factory ExperimentPlan.fromJson(Map<String, dynamic> json) {
    return ExperimentPlan(
      experimentId: _string(json['experiment_id']),
      action: _string(json['action']),
      whyItMatters: _string(json['why_it_matters']),
      deadline: _string(json['deadline']),
      successMetric: _string(json['success_metric']),
    );
  }

  final String experimentId;
  final String action;
  final String whyItMatters;
  final String deadline;
  final String successMetric;

  Map<String, Object> toJson() {
    return <String, Object>{
      'experiment_id': experimentId,
      'action': action,
      'why_it_matters': whyItMatters,
      'deadline': deadline,
      'success_metric': successMetric,
    };
  }
}

class IntelligenceFutureOption {
  const IntelligenceFutureOption({
    required this.futureId,
    required this.name,
    required this.thesis,
    required this.successProbability,
    required this.opportunityScore,
    required this.riskScore,
  });

  factory IntelligenceFutureOption.fromJson(Map<String, dynamic> json) {
    return IntelligenceFutureOption(
      futureId: _string(json['future_id']),
      name: _string(json['name']),
      thesis: _string(json['thesis']),
      successProbability: _double(json['success_probability']),
      opportunityScore: _double(json['opportunity_score']),
      riskScore: _double(json['risk_score']),
    );
  }

  final String futureId;
  final String name;
  final String thesis;
  final double successProbability;
  final double opportunityScore;
  final double riskScore;
}

class IntelligenceSignal {
  const IntelligenceSignal({
    required this.name,
    required this.title,
    required this.status,
    required this.summary,
    required this.latencyMs,
  });

  factory IntelligenceSignal.fromJson(Map<String, dynamic> json) {
    return IntelligenceSignal(
      name: _string(json['name']),
      title: _string(json['title']),
      status: _string(json['status'], fallback: 'unknown'),
      summary: _string(json['summary']),
      latencyMs: json['latency_ms'] is num
          ? (json['latency_ms'] as num).round()
          : null,
    );
  }

  final String name;
  final String title;
  final String status;
  final String summary;
  final int? latencyMs;

  bool get isHealthy => status == 'ok';
}

class OutcomeUpdateResult {
  const OutcomeUpdateResult({
    required this.executionScore,
    required this.confidenceDelta,
    required this.memoryId,
    required this.reputationEventId,
    required this.reputationScore,
    required this.trustLevel,
    required this.profileUpdates,
    required this.nextRecommendation,
    required this.memorySummary,
    required this.signals,
  });

  factory OutcomeUpdateResult.fromJson(Map<String, dynamic> json) {
    return OutcomeUpdateResult(
      executionScore: _double(json['execution_score']),
      confidenceDelta: _double(json['confidence_delta']),
      memoryId: _string(json['memory_id']),
      reputationEventId: _string(json['reputation_event_id']),
      reputationScore: json['reputation_score'] is num
          ? (json['reputation_score'] as num).round()
          : null,
      trustLevel: _string(json['trust_level']),
      profileUpdates: _parseStringList(json['profile_updates']),
      nextRecommendation: _string(json['next_recommendation']),
      memorySummary: _string(json['memory_summary']),
      signals: _parseIntelligenceSignals(json['signals']),
    );
  }

  final double executionScore;
  final double confidenceDelta;
  final String memoryId;
  final String reputationEventId;
  final int? reputationScore;
  final String trustLevel;
  final List<String> profileUpdates;
  final String nextRecommendation;
  final String memorySummary;
  final List<IntelligenceSignal> signals;

  bool get memorySaved => memoryId.isNotEmpty;
  bool get reputationLogged => reputationEventId.isNotEmpty;
}

List<IntelligenceFutureOption> _parseFutureOptions(Object? raw) {
  if (raw is! List<dynamic>) {
    return const <IntelligenceFutureOption>[];
  }
  return raw
      .whereType<Map<String, dynamic>>()
      .map(IntelligenceFutureOption.fromJson)
      .toList(growable: false);
}

List<IntelligenceSignal> _parseIntelligenceSignals(Object? raw) {
  if (raw is! List<dynamic>) {
    return const <IntelligenceSignal>[];
  }
  return raw
      .whereType<Map<String, dynamic>>()
      .map(IntelligenceSignal.fromJson)
      .toList(growable: false);
}

Map<String, String> _parseStringMap(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    return const <String, String>{};
  }
  return raw.map((key, value) => MapEntry(key, value.toString()));
}

double _double(Object? raw) {
  return raw is num ? raw.toDouble() : 0;
}

String _string(Object? raw, {String fallback = ''}) {
  return raw is String && raw.isNotEmpty ? raw : fallback;
}
