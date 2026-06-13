import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/profile_provider.dart';
import '../data/mission_control_api_client.dart';
import '../domain/mission_control_models.dart';
import 'mission_ai.dart';

const _kNoAiMessage =
    'Sign in to run Mission Control intelligence. Analysis runs through your account.';

/// Returns a [MissionAi] bound to the current OpenAI proxy + profile, or null
/// when there is no signed-in session.
MissionAi? _missionAi(Ref ref) {
  final openai = ref.read(openAIServiceProvider);
  if (openai == null) return null;
  final profile = ref.read(userProfileProvider).asData?.value;
  return MissionAi(openai, profile);
}

/// Optional self-hosted Mission Control gateway. Empty by default — when unset,
/// the dashboard renders the local snapshot instead of calling a backend.
const _missionGatewayUrl = String.fromEnvironment('ALTER_API_GATEWAY_URL');

final missionControlApiClientProvider = Provider<MissionControlApiClient>((
  ref,
) {
  final client = MissionControlApiClient(baseUrl: _missionGatewayUrl);
  ref.onDispose(client.close);
  return client;
});

final missionControlProvider = FutureProvider<MissionControlSnapshot>((ref) {
  // No external gateway configured → use the local snapshot directly. This
  // avoids a doomed network round-trip and console noise in production.
  if (_missionGatewayUrl.isEmpty) {
    return fallbackMissionControlSnapshot;
  }
  return ref
      .watch(missionControlApiClientProvider)
      .loadSnapshot(fallbackMissionControlSnapshot);
});

final missionDemoControllerProvider =
    NotifierProvider<MissionDemoController, MissionDemoState>(
      MissionDemoController.new,
    );

final intelligenceKernelControllerProvider =
    NotifierProvider<IntelligenceKernelController, IntelligenceKernelState>(
      IntelligenceKernelController.new,
    );

final futureTwinControllerProvider =
    NotifierProvider<FutureTwinController, FutureTwinState>(
      FutureTwinController.new,
    );

final proofCaptureControllerProvider =
    NotifierProvider<ProofCaptureController, ProofCaptureState>(
      ProofCaptureController.new,
    );

class ProofCaptureController extends Notifier<ProofCaptureState> {
  @override
  ProofCaptureState build() => const ProofCaptureState();

  Future<void> capture({
    required String objective,
    required String linkedGoal,
    required String linkedAction,
    required List<ProofEvidenceInput> evidence,
  }) async {
    final trimmed = objective.trim();
    if (trimmed.length < 3) {
      state = state.copyWith(errorMessage: 'Enter the future objective this proof updates.');
      return;
    }
    if (evidence.isEmpty) {
      state = state.copyWith(errorMessage: 'Add at least one proof item.');
      return;
    }
    final ai = _missionAi(ref);
    if (ai == null) {
      state = state.copyWith(errorMessage: _kNoAiMessage);
      return;
    }
    state = state.copyWith(isRunning: true, errorMessage: '');
    try {
      final result = await ai.captureProof(
        objective: trimmed,
        linkedGoal: linkedGoal.trim(),
        linkedAction: linkedAction.trim(),
        evidence: evidence,
      );
      state = state.copyWith(isRunning: false, result: result);
    } catch (error) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

class ProofCaptureState {
  const ProofCaptureState({
    this.isRunning = false,
    this.result,
    this.errorMessage = '',
  });

  final bool isRunning;
  final ProofCaptureResult? result;
  final String errorMessage;

  ProofCaptureState copyWith({
    bool? isRunning,
    ProofCaptureResult? result,
    String? errorMessage,
  }) {
    return ProofCaptureState(
      isRunning: isRunning ?? this.isRunning,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FutureTwinController extends Notifier<FutureTwinState> {
  @override
  FutureTwinState build() => const FutureTwinState();

  Future<void> buildTwin({
    required String objective,
    required List<FutureTwinEvidenceInput> evidence,
  }) async {
    final trimmed = objective.trim();
    if (trimmed.length < 3) {
      state = state.copyWith(errorMessage: 'Enter an objective for your Future Twin.');
      return;
    }
    final ai = _missionAi(ref);
    if (ai == null) {
      state = state.copyWith(errorMessage: _kNoAiMessage);
      return;
    }
    state = state.copyWith(isRunning: true, errorMessage: '');
    try {
      final result = await ai.buildTwin(objective: trimmed, evidence: evidence);
      state = state.copyWith(isRunning: false, result: result);
    } catch (error) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

class FutureTwinState {
  const FutureTwinState({
    this.isRunning = false,
    this.result,
    this.errorMessage = '',
  });

  final bool isRunning;
  final FutureTwinResult? result;
  final String errorMessage;

  FutureTwinState copyWith({
    bool? isRunning,
    FutureTwinResult? result,
    String? errorMessage,
  }) {
    return FutureTwinState(
      isRunning: isRunning ?? this.isRunning,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class IntelligenceKernelController extends Notifier<IntelligenceKernelState> {
  @override
  IntelligenceKernelState build() => const IntelligenceKernelState();

  Future<void> decide(String question) async {
    final trimmed = question.trim();
    if (trimmed.length < 3) {
      state = state.copyWith(errorMessage: 'Enter a decision to reason through.');
      return;
    }
    final ai = _missionAi(ref);
    if (ai == null) {
      state = state.copyWith(errorMessage: _kNoAiMessage);
      return;
    }
    state = state.copyWith(
      isRunning: true,
      errorMessage: '',
      clearOutcomeResult: true,
    );
    try {
      final report = await ai.decide(trimmed);
      state = state.copyWith(isRunning: false, report: report);
    } catch (error) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> recordOutcome({
    required bool didIt,
    required String whatHappened,
    required String whatLearned,
    required String successMetricResult,
    required double outcomeScore,
  }) async {
    final report = state.report;
    if (report == null) {
      state = state.copyWith(outcomeErrorMessage: 'Run a decision first.');
      return;
    }
    if (whatHappened.trim().length < 2 ||
        whatLearned.trim().length < 2 ||
        successMetricResult.trim().length < 2) {
      state = state.copyWith(
        outcomeErrorMessage: 'Add what happened, what you learned, and the metric result.',
      );
      return;
    }
    final ai = _missionAi(ref);
    if (ai == null) {
      state = state.copyWith(outcomeErrorMessage: _kNoAiMessage);
      return;
    }
    state = state.copyWith(isSubmittingOutcome: true, outcomeErrorMessage: '');
    try {
      final outcome = await ai.recordOutcome(
        report: report,
        didIt: didIt,
        whatHappened: whatHappened.trim(),
        whatLearned: whatLearned.trim(),
        successMetricResult: successMetricResult.trim(),
        outcomeScore: outcomeScore,
      );
      state = state.copyWith(
        isSubmittingOutcome: false,
        outcomeResult: outcome,
        outcomeErrorMessage: '',
      );
    } catch (error) {
      state = state.copyWith(
        isSubmittingOutcome: false,
        outcomeErrorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

class IntelligenceKernelState {
  const IntelligenceKernelState({
    this.isRunning = false,
    this.report,
    this.errorMessage = '',
    this.isSubmittingOutcome = false,
    this.outcomeResult,
    this.outcomeErrorMessage = '',
  });

  final bool isRunning;
  final IntelligenceDecisionReport? report;
  final String errorMessage;
  final bool isSubmittingOutcome;
  final OutcomeUpdateResult? outcomeResult;
  final String outcomeErrorMessage;

  IntelligenceKernelState copyWith({
    bool? isRunning,
    IntelligenceDecisionReport? report,
    String? errorMessage,
    bool? isSubmittingOutcome,
    OutcomeUpdateResult? outcomeResult,
    String? outcomeErrorMessage,
    bool clearOutcomeResult = false,
  }) {
    return IntelligenceKernelState(
      isRunning: isRunning ?? this.isRunning,
      report: report ?? this.report,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmittingOutcome: isSubmittingOutcome ?? this.isSubmittingOutcome,
      outcomeResult: clearOutcomeResult
          ? null
          : outcomeResult ?? this.outcomeResult,
      outcomeErrorMessage: outcomeErrorMessage ?? this.outcomeErrorMessage,
    );
  }
}

class MissionDemoController extends Notifier<MissionDemoState> {
  @override
  MissionDemoState build() => const MissionDemoState();

  Future<void> run(String objective) async {
    final trimmed = objective.trim();
    if (trimmed.length < 2) {
      state = state.copyWith(errorMessage: 'Enter a decision to simulate.');
      return;
    }
    final ai = _missionAi(ref);
    if (ai == null) {
      state = state.copyWith(errorMessage: _kNoAiMessage);
      return;
    }
    state = state.copyWith(isRunning: true, errorMessage: '');
    try {
      final result = await ai.runDemo(trimmed);
      state = state.copyWith(isRunning: false, result: result);
    } catch (error) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

class MissionDemoState {
  const MissionDemoState({
    this.isRunning = false,
    this.result,
    this.errorMessage = '',
  });

  final bool isRunning;
  final MissionDemoRun? result;
  final String errorMessage;

  MissionDemoState copyWith({
    bool? isRunning,
    MissionDemoRun? result,
    String? errorMessage,
  }) {
    return MissionDemoState(
      isRunning: isRunning ?? this.isRunning,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

const fallbackMissionControlSnapshot = MissionControlSnapshot(
  operatorName: 'Aria Shah',
  activeObjective: 'Package the AI networking demo and route the best intros.',
  readiness: 0.91,
  phoneModules: [
    MissionModule(
      id: 'voice',
      title: 'Voice',
      route: '/voice',
      surface: MissionSurface.phone,
      signal: 0.94,
      health: 0.96,
      status: 'Wake channel armed',
      cadence: 'Always-on',
      capabilities: ['Intent capture', 'Agent command', 'Memory entry'],
    ),
    MissionModule(
      id: 'camera',
      title: 'Camera',
      route: '/lens',
      surface: MissionSurface.phone,
      signal: 0.87,
      health: 0.89,
      status: 'Vision queue clear',
      cadence: 'Capture',
      capabilities: ['Resume scan', 'Deck scan', 'Product scan'],
    ),
    MissionModule(
      id: 'nfc',
      title: 'NFC',
      route: '/nfc',
      surface: MissionSurface.phone,
      signal: 0.82,
      health: 0.88,
      status: 'Tap profile ready',
      cadence: 'Proximity',
      capabilities: ['Portfolio', 'Resume', 'Match scoring'],
    ),
  ],
  laptopModules: [
    MissionModule(
      id: 'timelines',
      title: 'Future Timelines',
      route: '/simulator',
      surface: MissionSurface.laptop,
      signal: 0.91,
      health: 0.9,
      status: '3 futures modeled',
      cadence: 'Planning',
      capabilities: ['Salary path', 'Skills path', 'Risk forecast'],
    ),
    MissionModule(
      id: 'council',
      title: 'Clone Council',
      route: '/council',
      surface: MissionSurface.laptop,
      signal: 0.88,
      health: 0.92,
      status: '7 clones aligned',
      cadence: 'Debate',
      capabilities: ['Challenge', 'Consensus', 'Risks'],
    ),
    MissionModule(
      id: 'radar',
      title: 'Opportunity Radar',
      route: '/radar',
      surface: MissionSurface.laptop,
      signal: 0.93,
      health: 0.86,
      status: '18 signals ranked',
      cadence: 'Crawl',
      capabilities: ['Programs', 'Grants', 'Warm leads'],
    ),
    MissionModule(
      id: 'social',
      title: 'Social Graph',
      route: '/social',
      surface: MissionSurface.laptop,
      signal: 0.84,
      health: 0.91,
      status: 'Warm paths online',
      cadence: 'Graph',
      capabilities: ['Mentors', 'Recruiters', 'Team paths'],
    ),
    MissionModule(
      id: 'reputation',
      title: 'Reputation Engine',
      route: '/reputation',
      surface: MissionSurface.laptop,
      signal: 0.79,
      health: 0.87,
      status: 'Trust ledger stable',
      cadence: 'Ledger',
      capabilities: ['Follow-up', 'Delivery', 'Trust deltas'],
    ),
  ],
  metrics: [
    MissionMetric(
      label: 'Readiness',
      value: '91%',
      detail: 'Objective, graph, and radar are synchronized.',
      moduleId: 'timelines',
    ),
    MissionMetric(
      label: 'Warm Paths',
      value: '18',
      detail: 'Social graph has direct routes to design partners.',
      moduleId: 'social',
    ),
    MissionMetric(
      label: 'Radar Heat',
      value: '94',
      detail: 'Partnership signal is above launch threshold.',
      moduleId: 'radar',
    ),
    MissionMetric(
      label: 'Trust Delta',
      value: '+26',
      detail: 'Reputation improved across recent follow-ups.',
      moduleId: 'reputation',
    ),
  ],
  events: [
    MissionEvent(
      time: 'Now',
      title: 'NFC contact enriched into Social Graph',
      source: 'Phone',
      impact: 'New warm intro candidate',
    ),
    MissionEvent(
      time: '12m',
      title: 'Clone Council flagged beta onboarding risk',
      source: 'Laptop',
      impact: 'Add trust-first permission screen',
    ),
    MissionEvent(
      time: '24m',
      title: 'Opportunity Radar found founder cohort opening',
      source: 'Laptop',
      impact: 'Send application before Friday',
    ),
    MissionEvent(
      time: '41m',
      title: 'Camera scan created product memory',
      source: 'Phone',
      impact: 'Route to competitive teardown',
    ),
  ],
);
