import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alter_lens_api_client.dart';
import '../domain/alter_lens_models.dart';

final alterLensApiClientProvider = Provider<AlterLensApiClient>((ref) {
  final client = AlterLensApiClient(
    baseUrl: const String.fromEnvironment(
      'ALTER_LENS_URL',
      defaultValue: 'http://localhost:8130',
    ),
  );
  ref.onDispose(client.close);
  return client;
});

final alterLensControllerProvider =
    NotifierProvider<AlterLensController, AlterLensState>(
  AlterLensController.new,
);

class AlterLensController extends Notifier<AlterLensState> {
  @override
  AlterLensState build() => const AlterLensState();

  void selectScanType(LensScanType scanType) {
    state = state.copyWith(scanType: scanType, errorMessage: '');
  }

  Future<void> analyzeCapture({
    required List<int> imageBytes,
    required String filename,
    String userContext = '',
  }) async {
    state = state.copyWith(isAnalyzing: true, errorMessage: '');
    try {
      final result = await ref.read(alterLensApiClientProvider).analyzeImage(
            scanType: state.scanType,
            imageBytes: imageBytes,
            filename: filename,
            userContext: userContext,
          );
      state = state.copyWith(isAnalyzing: false, result: result);
    } catch (error) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: error.toString(),
      );
    }
  }

  void previewAnalysis() {
    state = state.copyWith(
      isAnalyzing: false,
      errorMessage: '',
      result: sampleLensResult(state.scanType),
    );
  }
}

class AlterLensState {
  const AlterLensState({
    this.scanType = LensScanType.resume,
    this.isAnalyzing = false,
    this.result,
    this.errorMessage = '',
  });

  final LensScanType scanType;
  final bool isAnalyzing;
  final LensScanResult? result;
  final String errorMessage;

  AlterLensState copyWith({
    LensScanType? scanType,
    bool? isAnalyzing,
    LensScanResult? result,
    String? errorMessage,
  }) {
    return AlterLensState(
      scanType: scanType ?? this.scanType,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

LensScanResult sampleLensResult(LensScanType scanType) {
  return LensScanResult(
    scanId: 'preview',
    scanType: scanType,
    detectedType: scanType.label,
    summary: 'OpenAI vision preview identified a high-signal '
        '${scanType.label.toLowerCase()} scan with enough structure to create '
        'memory, opportunities, and next actions.',
    confidence: 0.91,
    insights: const [
      LensInsightSignal(
        title: 'Clear signal cluster',
        detail:
            'The capture has enough semantic structure to extract entities, intent, and context.',
        confidence: 0.9,
        tags: ['context', 'memory'],
      ),
      LensInsightSignal(
        title: 'Follow-up path is actionable',
        detail:
            'The content can route into Opportunity Radar, Clone Council, or Memory Graph.',
        confidence: 0.86,
        tags: ['opportunity', 'routing'],
      ),
    ],
    opportunities: const [
      LensOpportunity(
        title: 'Create a warm follow-up packet',
        whyNow: 'The scan contains enough context to personalize outreach.',
        nextStep: 'Save this as a memory and ask ALTER to draft the next move.',
        score: 87,
      ),
      LensOpportunity(
        title: 'Route to Opportunity Radar',
        whyNow: 'Detected topics can be matched against active programs.',
        nextStep: 'Search matching grants, cohorts, roles, or communities.',
        score: 78,
      ),
    ],
    recommendations: const [
      LensRecommendation(
        action: 'Save summary and entities to Personal Memory Graph.',
        priority: LensPriority.high,
        rationale: 'This keeps the scan useful after the moment passes.',
      ),
      LensRecommendation(
        action: 'Ask Clone Council to pressure-test the strongest opportunity.',
        priority: LensPriority.medium,
        rationale: 'Multi-agent critique can turn the scan into a decision.',
      ),
    ],
    extractedEntities: const {
      'topics': ['AI', 'networking', 'career signal'],
      'actions': ['save memory', 'draft follow-up'],
    },
    memoryCandidates: const ['scan_summary', 'opportunity_signal', 'next_action'],
    createdAt: DateTime.now(),
  );
}
