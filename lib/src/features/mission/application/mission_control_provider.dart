import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/application/backend_config_controller.dart';
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
Future<MissionControlApiClient?> _missionGateway(
  Ref ref, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final config = await ref.read(backendConfigProvider.future);
  if (!config.hasGateway) return null;
  return MissionControlApiClient(baseUrl: config.gatewayUrl, timeout: timeout);
}

String _fallbackError(Object? gatewayError) {
  if (gatewayError == null) return _kNoAiMessage;
  return 'Backend gateway failed: ${gatewayError.toString().replaceFirst('Exception: ', '')}';
}

final missionControlProvider = FutureProvider<MissionControlSnapshot>((
  ref,
) async {
  // No external gateway configured → use the local snapshot directly. This
  // avoids a doomed network round-trip and console noise in production.
  final client = await _missionGateway(
    ref,
    timeout: const Duration(seconds: 5),
  );
  if (client == null) {
    return fallbackMissionControlSnapshot;
  }
  ref.onDispose(client.close);
  try {
    return await client.loadSnapshot(fallbackMissionControlSnapshot);
  } catch (_) {
    return fallbackMissionControlSnapshot;
  }
});

final missionOrchestrationControllerProvider =
    NotifierProvider<MissionOrchestrationController, MissionOrchestrationState>(
      MissionOrchestrationController.new,
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
      state = state.copyWith(
        errorMessage: 'Enter the future objective this proof updates.',
      );
      return;
    }
    if (evidence.isEmpty) {
      state = state.copyWith(errorMessage: 'Add at least one proof item.');
      return;
    }
    state = state.copyWith(isRunning: true, errorMessage: '');
    Object? gatewayError;
    final gateway = await _missionGateway(ref);
    if (gateway != null) {
      try {
        final result = await gateway.captureProof(
          objective: trimmed,
          linkedGoal: linkedGoal.trim(),
          linkedAction: linkedAction.trim(),
          evidence: evidence,
        );
        state = state.copyWith(isRunning: false, result: result);
        gateway.close();
        return;
      } catch (error) {
        gatewayError = error;
        gateway.close();
      }
    }
    final ai = _missionAi(ref);
    if (ai == null) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: _fallbackError(gatewayError),
      );
      return;
    }
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
      state = state.copyWith(
        errorMessage: 'Enter an objective for your Future Twin.',
      );
      return;
    }
    state = state.copyWith(isRunning: true, errorMessage: '');
    Object? gatewayError;
    final gateway = await _missionGateway(ref);
    if (gateway != null) {
      try {
        final result = await gateway.buildFutureTwin(
          objective: trimmed,
          profile: ref.read(userProfileProvider).asData?.value,
          evidence: evidence,
        );
        state = state.copyWith(isRunning: false, result: result);
        gateway.close();
        return;
      } catch (error) {
        gatewayError = error;
        gateway.close();
      }
    }
    final ai = _missionAi(ref);
    if (ai == null) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: _fallbackError(gatewayError),
      );
      return;
    }
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
      state = state.copyWith(
        errorMessage: 'Enter a decision to reason through.',
      );
      return;
    }
    state = state.copyWith(
      isRunning: true,
      errorMessage: '',
      clearOutcomeResult: true,
    );
    Object? gatewayError;
    final gateway = await _missionGateway(ref);
    if (gateway != null) {
      try {
        final report = await gateway.decide(
          question: trimmed,
          profile: ref.read(userProfileProvider).asData?.value,
        );
        state = state.copyWith(isRunning: false, report: report);
        gateway.close();
        return;
      } catch (error) {
        gatewayError = error;
        gateway.close();
      }
    }
    final ai = _missionAi(ref);
    if (ai == null) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: _fallbackError(gatewayError),
      );
      return;
    }
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
        outcomeErrorMessage:
            'Add what happened, what you learned, and the metric result.',
      );
      return;
    }
    state = state.copyWith(isSubmittingOutcome: true, outcomeErrorMessage: '');
    Object? gatewayError;
    final gateway = await _missionGateway(ref);
    if (gateway != null) {
      try {
        final outcome = await gateway.recordOutcome(
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
        gateway.close();
        return;
      } catch (error) {
        gatewayError = error;
        gateway.close();
      }
    }
    final ai = _missionAi(ref);
    if (ai == null) {
      state = state.copyWith(
        isSubmittingOutcome: false,
        outcomeErrorMessage: _fallbackError(gatewayError),
      );
      return;
    }
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

class MissionOrchestrationController
    extends Notifier<MissionOrchestrationState> {
  @override
  MissionOrchestrationState build() => const MissionOrchestrationState();

  Future<void> run(String objective) async {
    final trimmed = objective.trim();
    if (trimmed.length < 2) {
      state = state.copyWith(errorMessage: 'Enter a decision to simulate.');
      return;
    }
    state = state.copyWith(isRunning: true, errorMessage: '');
    Object? gatewayError;
    final gateway = await _missionGateway(ref);
    if (gateway != null) {
      try {
        final profile = ref.read(userProfileProvider).asData?.value;
        final result = await gateway.runFutureOsOrchestration(
          objective: trimmed,
          profile: profile,
        );
        state = state.copyWith(isRunning: false, result: result);
        gateway.close();
        return;
      } catch (error) {
        gatewayError = error;
        gateway.close();
      }
    }
    final ai = _missionAi(ref);
    if (ai == null) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: _fallbackError(gatewayError),
      );
      return;
    }
    try {
      final result = await ai.runOrchestration(trimmed);
      state = state.copyWith(isRunning: false, result: result);
    } catch (error) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

class MissionOrchestrationState {
  const MissionOrchestrationState({
    this.isRunning = false,
    this.result,
    this.errorMessage = '',
  });

  final bool isRunning;
  final MissionOrchestrationRun? result;
  final String errorMessage;

  MissionOrchestrationState copyWith({
    bool? isRunning,
    MissionOrchestrationRun? result,
    String? errorMessage,
  }) {
    return MissionOrchestrationState(
      isRunning: isRunning ?? this.isRunning,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

const fallbackMissionControlSnapshot = MissionControlSnapshot(
  operatorName: 'Profile not loaded',
  activeObjective:
      'Connect the backend gateway or run an intelligence action to populate Mission Control.',
  readiness: 0,
  backendStatus: 'not connected',
  phoneModules: [
    MissionModule(
      id: 'voice',
      title: 'Voice',
      route: '/voice',
      surface: MissionSurface.phone,
      signal: 0,
      health: 0,
      status: 'Waiting for runtime state',
      cadence: 'Always-on',
      capabilities: ['Intent capture', 'Agent command', 'Memory entry'],
    ),
    MissionModule(
      id: 'camera',
      title: 'Camera',
      route: '/lens',
      surface: MissionSurface.phone,
      signal: 0,
      health: 0,
      status: 'Waiting for camera analysis',
      cadence: 'Capture',
      capabilities: ['Resume scan', 'Deck scan', 'Product scan'],
    ),
    MissionModule(
      id: 'nfc',
      title: 'NFC',
      route: '/nfc',
      surface: MissionSurface.phone,
      signal: 0,
      health: 0,
      status: 'Waiting for NFC exchange',
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
      signal: 0,
      health: 0,
      status: 'No scenarios loaded',
      cadence: 'Planning',
      capabilities: ['Salary path', 'Skills path', 'Risk forecast'],
    ),
    MissionModule(
      id: 'council',
      title: 'Clone Council',
      route: '/council',
      surface: MissionSurface.laptop,
      signal: 0,
      health: 0,
      status: 'No debate loaded',
      cadence: 'Debate',
      capabilities: ['Challenge', 'Consensus', 'Risks'],
    ),
    MissionModule(
      id: 'radar',
      title: 'Opportunity Radar',
      route: '/radar',
      surface: MissionSurface.laptop,
      signal: 0,
      health: 0,
      status: 'No opportunity signals',
      cadence: 'Crawl',
      capabilities: ['Programs', 'Grants', 'Warm leads'],
    ),
    MissionModule(
      id: 'social',
      title: 'Social Graph',
      route: '/social',
      surface: MissionSurface.laptop,
      signal: 0,
      health: 0,
      status: 'No contacts loaded',
      cadence: 'Graph',
      capabilities: ['Mentors', 'Recruiters', 'Team paths'],
    ),
    MissionModule(
      id: 'reputation',
      title: 'Reputation Engine',
      route: '/reputation',
      surface: MissionSurface.laptop,
      signal: 0,
      health: 0,
      status: 'No reputation events',
      cadence: 'Ledger',
      capabilities: ['Follow-up', 'Delivery', 'Trust deltas'],
    ),
  ],
  metrics: [],
  events: [],
);
