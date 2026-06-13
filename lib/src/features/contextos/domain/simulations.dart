import 'package:flutter/material.dart';

import '../../../core/theme/alter_palette.dart';

// ---------------------------------------------------------------------------
// DayTwin — a living model of today.
// ---------------------------------------------------------------------------

enum DayPathType {
  defaultDay('Default Day', AlterPalette.cyan),
  riskDay('Risk Day', AlterPalette.danger),
  optimizedDay('Optimized Day', AlterPalette.mint);

  const DayPathType(this.label, this.color);
  final String label;
  final Color color;

  static DayPathType fromId(String v) {
    final s = v.toLowerCase();
    if (s.contains('risk')) return DayPathType.riskDay;
    if (s.contains('optim')) return DayPathType.optimizedDay;
    return DayPathType.defaultDay;
  }
}

class DayBlock {
  const DayBlock({
    required this.time,
    required this.title,
    required this.note,
    required this.stress,
  });

  factory DayBlock.fromJson(Map<String, dynamic> j) => DayBlock(
        time: (j['time'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
        stress: _d(j['stress']),
      );

  final String time;
  final String title;
  final String note;
  final double stress; // 0..1
}

class DayPath {
  const DayPath({
    required this.type,
    required this.summary,
    required this.dayScore,
    required this.blocks,
  });

  factory DayPath.fromJson(Map<String, dynamic> j) => DayPath(
        type: DayPathType.fromId((j['type'] ?? '').toString()),
        summary: (j['summary'] ?? '').toString(),
        dayScore: _d(j['day_score']),
        blocks: _list(j['blocks'], DayBlock.fromJson),
      );

  final DayPathType type;
  final String summary;
  final double dayScore; // 0..1
  final List<DayBlock> blocks;
}

class DayTwinResult {
  const DayTwinResult({
    required this.headline,
    required this.pressurePoints,
    required this.paths,
    required this.nextBestMove,
    required this.cloudUsed,
  });

  factory DayTwinResult.fromJson(Map<String, dynamic> j, {required bool cloud}) =>
      DayTwinResult(
        headline: (j['headline'] ?? 'Your day, modeled').toString(),
        pressurePoints: _strs(j['pressure_points']),
        paths: _list(j['paths'], DayPath.fromJson),
        nextBestMove: (j['next_best_move'] ?? '').toString(),
        cloudUsed: cloud,
      );

  final String headline;
  final List<String> pressurePoints;
  final List<DayPath> paths;
  final String nextBestMove;
  final bool cloudUsed;

  static DayTwinResult sample(String seed) => DayTwinResult(
        cloudUsed: false,
        headline: 'Tight evening — protect the airport run',
        pressurePoints: const [
          '17:00 deliverable overlaps the commute window',
          'Cab booked late vs. 19:55 boarding cut-off',
          'No buffer if ORR traffic spikes',
        ],
        nextBestMove:
            'Move the cab 30 min earlier and pre-pack now; ship the deliverable by 16:30.',
        paths: const [
          DayPath(
            type: DayPathType.defaultDay,
            summary: 'If nothing changes: you leave on time but with zero buffer.',
            dayScore: 0.62,
            blocks: [
              DayBlock(time: '15:00', title: 'Deep work', note: 'Finish deliverable', stress: 0.4),
              DayBlock(time: '17:00', title: 'Handoff', note: 'Send for review', stress: 0.55),
              DayBlock(time: '18:40', title: 'Cab', note: 'Leave for airport', stress: 0.6),
              DayBlock(time: '19:55', title: 'Boarding', note: 'No buffer', stress: 0.75),
            ],
          ),
          DayPath(
            type: DayPathType.riskDay,
            summary: 'If traffic spikes or review drags: you miss the gate.',
            dayScore: 0.34,
            blocks: [
              DayBlock(time: '17:30', title: 'Review drags', note: 'Edits needed', stress: 0.7),
              DayBlock(time: '19:10', title: 'ORR jam', note: '25 min delay', stress: 0.85),
              DayBlock(time: '20:00', title: 'Gate closed', note: 'Missed flight', stress: 0.95),
            ],
          ),
          DayPath(
            type: DayPathType.optimizedDay,
            summary: 'Front-load the work and leave early: calm, with buffer.',
            dayScore: 0.86,
            blocks: [
              DayBlock(time: '16:30', title: 'Ship early', note: 'Deliverable out', stress: 0.3),
              DayBlock(time: '18:10', title: 'Cab early', note: '30 min buffer', stress: 0.35),
              DayBlock(time: '19:20', title: 'At terminal', note: 'Relaxed', stress: 0.2),
            ],
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// FutureTwin — bigger decisions, three paths.
// ---------------------------------------------------------------------------

enum FuturePathType {
  safe('Safe Path', AlterPalette.mint),
  smart('Smart Path', AlterPalette.cyan),
  bold('Bold Path', AlterPalette.aura);

  const FuturePathType(this.label, this.color);
  final String label;
  final Color color;

  static FuturePathType fromId(String v) {
    final s = v.toLowerCase();
    if (s.contains('bold')) return FuturePathType.bold;
    if (s.contains('smart')) return FuturePathType.smart;
    return FuturePathType.safe;
  }
}

class FuturePath {
  const FuturePath({
    required this.type,
    required this.thesis,
    required this.effort,
    required this.risk,
    required this.upside,
    required this.regret,
    required this.roadmap,
  });

  factory FuturePath.fromJson(Map<String, dynamic> j) => FuturePath(
        type: FuturePathType.fromId((j['type'] ?? '').toString()),
        thesis: (j['thesis'] ?? '').toString(),
        effort: _d(j['effort']),
        risk: _d(j['risk']),
        upside: _d(j['upside']),
        regret: _d(j['regret']),
        roadmap: _strs(j['roadmap']),
      );

  final FuturePathType type;
  final String thesis;
  final double effort; // 0..1
  final double risk; // 0..1
  final double upside; // 0..1
  final double regret; // 0..1
  final List<String> roadmap;
}

class FutureTwinResult {
  const FutureTwinResult({
    required this.headline,
    required this.summary,
    required this.paths,
    required this.recommended,
    required this.regretMinimizer,
    required this.cloudUsed,
  });

  factory FutureTwinResult.fromJson(Map<String, dynamic> j,
          {required bool cloud}) =>
      FutureTwinResult(
        headline: (j['headline'] ?? 'Three futures, compared').toString(),
        summary: (j['summary'] ?? '').toString(),
        paths: _list(j['paths'], FuturePath.fromJson),
        recommended: (j['recommended'] ?? '').toString(),
        regretMinimizer: (j['regret_minimizer'] ?? '').toString(),
        cloudUsed: cloud,
      );

  final String headline;
  final String summary;
  final List<FuturePath> paths;
  final String recommended; // safe | smart | bold
  final String regretMinimizer;
  final bool cloudUsed;

  FuturePathType? get recommendedType => recommended.isEmpty
      ? null
      : FuturePathType.fromId(recommended);

  static FutureTwinResult sample(String seed) => FutureTwinResult(
        cloudUsed: false,
        headline: 'Stay, level up, or leap',
        summary:
            'The decision turns on runway and conviction. The smart path buys '
            'evidence before you commit either way.',
        recommended: 'smart',
        regretMinimizer:
            'You most regret moving without proof. Run a 90-day validation first.',
        paths: const [
          FuturePath(
            type: FuturePathType.safe,
            thesis: 'Stay and compound: deepen your current role, bank stability.',
            effort: 0.3,
            risk: 0.2,
            upside: 0.4,
            regret: 0.5,
            roadmap: [
              'Lock a measurable win this quarter',
              'Negotiate scope toward the skills you want',
              'Reassess in 6 months with data',
            ],
          ),
          FuturePath(
            type: FuturePathType.smart,
            thesis: 'Validate in parallel: build proof before you switch.',
            effort: 0.6,
            risk: 0.4,
            upside: 0.75,
            regret: 0.25,
            roadmap: [
              'Ship one real artifact in the new direction',
              'Get 3 signals of demand from the market',
              'Decide with evidence at day 90',
            ],
          ),
          FuturePath(
            type: FuturePathType.bold,
            thesis: 'Commit fully now: leap and force momentum.',
            effort: 0.9,
            risk: 0.75,
            upside: 0.95,
            regret: 0.45,
            roadmap: [
              'Set a 60-day runway and a hard deadline',
              'Go public to create accountability',
              'Cut the fallback to force focus',
            ],
          ),
        ],
      );
}

// --- shared json helpers ---
double _d(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

List<String> _strs(Object? v) => v is List
    ? v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
    : const [];

List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) f) => v is List
    ? v
        .whereType<Map>()
        .map((e) => f(Map<String, dynamic>.from(e)))
        .toList()
    : const [];
