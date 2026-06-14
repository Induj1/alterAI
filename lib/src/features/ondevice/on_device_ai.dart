import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../privacy/data/context_privacy_filter.dart';

final onDeviceAiProvider = Provider<OnDeviceAi>(
  (ref) => const HeuristicOnDeviceAi(),
);

/// Lightweight, private, on-device tasks. The default implementation is a pure
/// heuristic that always works with no model — the stub/fallback so the app is
/// never blocked when platform AI (Gemini Nano, LiteRT, Apple Foundation
/// Models, on-device Gemma) is unavailable or offline. A model-backed
/// implementation can be swapped in behind this same interface later.
abstract class OnDeviceAi {
  /// A coarse snake_case intent label for [text].
  Future<String> classifyIntent(String text);

  /// Whether the request likely needs heavy cloud reasoning (vs a quick reply).
  /// Used to route to a stronger cloud model only when it's worth it.
  Future<bool> needsDeepReasoning(String text);

  /// An extractive on-device summary, capped to roughly [maxWords] words.
  Future<String> summarize(String text, {int maxWords = 40});

  /// Redact obvious PII before anything leaves the device.
  Future<String> redact(String text);

  /// A short proactive nudge draft from a one-line [context].
  Future<String> draftNudge(String context);
}

class HeuristicOnDeviceAi implements OnDeviceAi {
  const HeuristicOnDeviceAi();

  static const _intents = <String, List<String>>{
    'schedule': ['remind', 'schedule', 'calendar', 'meeting', 'appointment'],
    'message': ['message', 'text', 'whatsapp', 'email', 'reply', 'send'],
    'call': ['call', 'dial', 'phone'],
    'search': ['find', 'search', 'look up', 'discover', 'opportunit'],
    'navigate': ['open', 'go to', 'launch', 'navigate'],
    'decision': [
      'should i',
      'decide',
      'decision',
      'pros and cons',
      'trade-off',
      'tradeoff',
      'weigh',
      'compare',
    ],
    'planning': ['plan', 'roadmap', 'steps to', 'how do i'],
    'reflect': ['analyze', 'why', 'explain', 'reason', 'evaluate'],
  };

  @override
  Future<String> classifyIntent(String text) async {
    final t = text.toLowerCase();
    for (final entry in _intents.entries) {
      if (entry.value.any(t.contains)) return entry.key;
    }
    return 'chat';
  }

  @override
  Future<bool> needsDeepReasoning(String text) async {
    if (text.length > 220) return true;
    final intent = await classifyIntent(text);
    return intent == 'decision' || intent == 'planning' || intent == 'reflect';
  }

  @override
  Future<String> summarize(String text, {int maxWords = 40}) async {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length <= maxWords) return text.trim();
    return '${words.take(maxWords).join(' ')}…';
  }

  @override
  Future<String> redact(String text) async {
    // Reuse the cloud-bound privacy filter, but keep full length (redact only).
    return const ContextPrivacyFilter(maxChars: 1 << 30).filter(text);
  }

  @override
  Future<String> draftNudge(String context) async {
    final clean = context.trim();
    if (clean.isEmpty) return 'Want me to help you plan your next move?';
    final short = clean.length > 90 ? '${clean.substring(0, 90)}…' : clean;
    return 'Based on "$short" — want me to take the next step on this?';
  }
}
