import 'package:flutter/material.dart';

import '../../../core/theme/alter_palette.dart';

/// The five inner voices ALTER convenes for important decisions.
enum CouncilAgent {
  practical('practical', 'Practical Me', 'gets it done sensibly',
      AlterPalette.iris, Icons.construction),
  risk('risk', 'Risk Me', 'guards the downside', AlterPalette.danger,
      Icons.gpp_maybe_outlined),
  future('future', 'Future Me', 'thinks in years', AlterPalette.cyan,
      Icons.timeline),
  skeptic('skeptic', 'Skeptic Me', 'distrusts the obvious', AlterPalette.amber,
      Icons.psychology_alt_outlined),
  action('action', 'Action Me', 'turns it into moves', AlterPalette.mint,
      Icons.bolt);

  const CouncilAgent(this.id, this.label, this.tagline, this.color, this.icon);

  final String id;
  final String label;
  final String tagline;
  final Color color;
  final IconData icon;

  static CouncilAgent fromId(String v) {
    final id = v.toLowerCase();
    const aliases = {
      'present': CouncilAgent.practical,
      'future': CouncilAgent.future,
      'realist': CouncilAgent.skeptic,
      'strategist': CouncilAgent.action,
      'values': CouncilAgent.risk,
    };
    if (aliases.containsKey(id)) return aliases[id]!;
    return CouncilAgent.values.firstWhere(
      (a) => a.id == id,
      orElse: () => CouncilAgent.practical,
    );
  }
}

class CouncilVoice {
  const CouncilVoice({
    required this.agent,
    required this.stance,
    required this.take,
    required this.confidence,
  });

  factory CouncilVoice.fromJson(Map<String, dynamic> j) => CouncilVoice(
        agent: CouncilAgent.fromId((j['agent'] ?? 'practical').toString()),
        stance: (j['stance'] ?? '').toString(),
        take: (j['take'] ?? '').toString(),
        confidence: j['confidence'] is num
            ? (j['confidence'] as num).toDouble()
            : 0.6,
      );

  final CouncilAgent agent;
  final String stance;
  final String take;
  final double confidence;
}

class CouncilResult {
  const CouncilResult({
    required this.voices,
    required this.consensus,
    required this.recommendation,
    required this.dissent,
    required this.cloudUsed,
  });

  factory CouncilResult.fromJson(Map<String, dynamic> j, {required bool cloud}) {
    final voices = (j['voices'] is List)
        ? (j['voices'] as List)
            .whereType<Map>()
            .map((e) => CouncilVoice.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <CouncilVoice>[];
    return CouncilResult(
      voices: voices,
      consensus: (j['consensus'] ?? '').toString(),
      recommendation: (j['recommendation'] ?? '').toString(),
      dissent: (j['dissent'] ?? '').toString(),
      cloudUsed: cloud,
    );
  }

  final List<CouncilVoice> voices;
  final String consensus;
  final String recommendation;
  final String dissent;
  final bool cloudUsed;

  static CouncilResult sample(String topic) => const CouncilResult(
        cloudUsed: false,
        consensus:
            'Four of five voices agree: do not act on this in the moment. Verify '
            'through an official channel first, then decide calmly.',
        recommendation:
            'Pause. Confirm the source independently. If it is real, it will '
            'survive a five-minute check.',
        dissent:
            'Action Me notes that waiting has a cost too — set a deadline so '
            '“verify first” doesn’t become “never decide”.',
        voices: [
          CouncilVoice(
            agent: CouncilAgent.practical,
            stance: 'Verify before acting',
            take:
                'The simplest safe move is a 5-minute independent check. Low cost, '
                'high protection.',
            confidence: 0.82,
          ),
          CouncilVoice(
            agent: CouncilAgent.risk,
            stance: 'Assume it is hostile until proven safe',
            take:
                'The downside (money, identity) dwarfs the upside of acting fast. '
                'Treat urgency as a red flag.',
            confidence: 0.88,
          ),
          CouncilVoice(
            agent: CouncilAgent.future,
            stance: 'Protect the long game',
            take:
                'One compromised account can cascade for months. Future you wants '
                'you to slow down here.',
            confidence: 0.79,
          ),
          CouncilVoice(
            agent: CouncilAgent.skeptic,
            stance: 'The framing is doing work',
            take:
                'Why the pressure and secrecy? Legitimate institutions do not rush '
                'you or forbid you from checking.',
            confidence: 0.85,
          ),
          CouncilVoice(
            agent: CouncilAgent.action,
            stance: 'Decide with a deadline',
            take:
                'Verify now, and if it clears, act within the hour. Don’t let '
                'caution become paralysis.',
            confidence: 0.7,
          ),
        ],
      );
}
