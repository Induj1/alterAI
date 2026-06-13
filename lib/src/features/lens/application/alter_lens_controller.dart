import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/profile_provider.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/alter_lens_models.dart';

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
    final openai = ref.read(openAIServiceProvider);
    if (openai == null) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage:
            'Sign in to use ALTER Lens. Vision analysis runs through your account.',
      );
      return;
    }

    state = state.copyWith(isAnalyzing: true, errorMessage: '');
    try {
      final profile = ref.read(userProfileProvider).asData?.value;
      final mime = _mimeFor(filename);
      final b64 = base64Encode(imageBytes);

      final raw = await openai.chat(
        model: 'gpt-4o-mini',
        jsonMode: true,
        temperature: 0.4,
        maxTokens: 1600,
        messages: [
          {'role': 'system', 'content': _systemPrompt(state.scanType, profile)},
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': userContext.trim().isEmpty
                    ? 'Analyze this ${state.scanType.label.toLowerCase()} capture.'
                    : 'Analyze this ${state.scanType.label.toLowerCase()} capture. '
                        'Context from me: $userContext',
              },
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mime;base64,$b64'},
              },
            ],
          },
        ],
      );

      final cleaned = _stripFences(raw);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      // Backfill fields the model may omit.
      json['scan_id'] ??= 'scan_${DateTime.now().millisecondsSinceEpoch}';
      json['scan_type'] ??= state.scanType.apiValue;
      json['created_at'] ??= DateTime.now().toIso8601String();

      state = state.copyWith(
        isAnalyzing: false,
        result: LensScanResult.fromJson(json),
      );
    } catch (error) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
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

  String _systemPrompt(LensScanType scanType, UserProfile? profile) {
    final who = profile == null || profile.displayName.isEmpty
        ? ''
        : 'The user is ${profile.displayName}'
            '${profile.role.isNotEmpty ? ', a ${profile.role}' : ''}'
            '${profile.goals.isNotEmpty ? '. Their goals: ${profile.goals.join(', ')}' : ''}. ';

    return 'You are ALTER Lens, a vision analyst that turns a captured '
        '${scanType.label.toLowerCase()} image into structured, actionable '
        'intelligence for a personal AI operating system. '
        '${who}Read the image carefully and respond with ONLY a JSON object '
        '(no markdown) matching exactly this schema:\n'
        '{\n'
        '  "scan_id": string,\n'
        '  "scan_type": "${scanType.apiValue}",\n'
        '  "detected_type": string,            // what you actually see\n'
        '  "summary": string,                  // 1-2 sentences\n'
        '  "confidence": number,               // 0..1\n'
        '  "insights": [ {"title": string, "detail": string, "confidence": number, "tags": [string]} ],\n'
        '  "opportunities": [ {"title": string, "why_now": string, "next_step": string, "score": number} ],  // score 0..100\n'
        '  "recommendations": [ {"action": string, "priority": "low|medium|high|urgent", "rationale": string} ],\n'
        '  "extracted_entities": { "topics": [string], "people": [string], "actions": [string] },\n'
        '  "memory_candidates": [string],\n'
        '  "created_at": string                // ISO8601\n'
        '}\n'
        'Provide 2-3 insights, 2-3 opportunities, and 2-3 recommendations. '
        'Be specific to what is actually visible. If the image is unreadable, '
        'say so honestly in the summary and lower the confidence.';
  }

  String _stripFences(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```(?:json)?\s*\n?'), '');
      if (s.endsWith('```')) s = s.substring(0, s.length - 3);
    }
    return s.trim();
  }

  String _mimeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
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
