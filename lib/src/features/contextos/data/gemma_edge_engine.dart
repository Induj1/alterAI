import 'package:flutter_gemma/flutter_gemma.dart';

import '../domain/contextos_models.dart';
import 'local_gemma_engine.dart';

/// On-device Gemma 4 edge engine. Redaction + signals stay heuristic;
/// risk verdict and reason come from Gemma via LiteRT-LM.
class GemmaEdgeEngine extends HeuristicGemmaEngine {
  GemmaEdgeEngine(this._model);

  final InferenceModel _model;

  @override
  Future<EdgeTriage> analyzeAsync(String input) async {
    final base = analyze(input);
    try {
      final session = await _model.createSession(temperature: 0.1, topK: 1);
      await session.addQueryChunk(
        Message.text(text: _prompt(base.redactedText), isUser: true),
      );
      final raw = await session.getResponse();
      await session.close();

      final verdict = _parseVerdict(raw);
      if (verdict == null) return base;

      final reason = _parseReason(raw);
      return EdgeTriage(
        redactedText: base.redactedText,
        redactedFields: base.redactedFields,
        coarseVerdict: verdict,
        signals: base.signals,
        shouldEscalate: verdict != RiskVerdict.safe || input.length > 280,
        summary: reason.isNotEmpty
            ? 'Gemma 4 on-device: $reason'
            : base.summary,
      );
    } catch (_) {
      return base;
    }
  }

  String _prompt(String redacted) =>
      'You are an on-device phone safety classifier. Classify the risk of acting '
      'on this message/notification. Reply with EXACTLY one label from '
      '[SAFE, CAUTION, VERIFY, DANGEROUS] then " - " then a short reason '
      '(max 14 words). No other text.\n\nMessage:\n"""\n$redacted\n"""\n\nAnswer:';

  RiskVerdict? _parseVerdict(String raw) {
    final u = raw.toUpperCase();
    if (u.contains('DANGEROUS')) return RiskVerdict.dangerous;
    if (u.contains('VERIFY')) return RiskVerdict.needsVerification;
    if (u.contains('CAUTION')) return RiskVerdict.caution;
    if (u.contains('SAFE')) return RiskVerdict.safe;
    return null;
  }

  String _parseReason(String raw) {
    final dash = raw.indexOf(' - ');
    if (dash >= 0 && dash + 3 < raw.length) {
      return raw.substring(dash + 3).trim();
    }
    return raw.trim();
  }
}
