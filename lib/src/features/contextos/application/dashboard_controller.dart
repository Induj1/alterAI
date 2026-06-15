import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../../../data/local/dao_providers.dart';
import '../domain/contextos_models.dart';

class LedgerEntry {
  const LedgerEntry({
    required this.headline,
    required this.verdict,
    required this.confidence,
    required this.cloudUsed,
    required this.timeLabel,
  });

  final String headline;
  final RiskVerdict verdict;
  final double confidence;
  final bool cloudUsed;
  final String timeLabel;
}

class AuditEntry {
  const AuditEntry({
    required this.kind,
    required this.detail,
    required this.edgeState,
    required this.timeLabel,
  });

  final String kind;
  final String detail;
  final String edgeState;
  final String timeLabel;
}

class DashboardData {
  const DashboardData({
    required this.ledger,
    required this.riskMap,
    required this.audit,
    required this.momentCount,
    required this.persisted,
  });

  final List<LedgerEntry> ledger;
  final Map<RiskVerdict, int> riskMap;
  final List<AuditEntry> audit;
  final int momentCount;
  final bool persisted;

  static const empty = DashboardData(
    ledger: [],
    riskMap: {},
    audit: [],
    momentCount: 0,
    persisted: false,
  );
}

final contextDashboardProvider =
    AsyncNotifierProvider<ContextDashboardController, DashboardData>(
  ContextDashboardController.new,
);

class ContextDashboardController extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() => _load();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _load());
  }

  Future<DashboardData> _load() async {
    ref.watch(isDbUnlockedProvider);
    final userId = ref.read(localUserIdProvider);
    if (userId == null) return DashboardData.empty;

    var persisted = false;
    final ledger = <LedgerEntry>[];
    final riskMap = <RiskVerdict, int>{};
    final audit = <AuditEntry>[];
    var momentCount = 0;

    final dao = ref.read(contextOsDaoProvider);

    try {
      final rows = await dao.listRiskAnalyses(userId);
      persisted = true;
      for (final r in rows.take(40)) {
        final v = RiskVerdict.fromId(r.verdict);
        riskMap[v] = (riskMap[v] ?? 0) + 1;
        ledger.add(LedgerEntry(
          headline: r.headline.isEmpty ? 'Moment' : r.headline,
          verdict: v,
          confidence: r.confidence,
          cloudUsed: r.cloudUsed,
          timeLabel: _time(r.createdAt.toIso8601String()),
        ));
      }
    } catch (_) {}

    try {
      final rows = await dao.listAuditEvents(userId);
      persisted = true;
      for (final r in rows.take(30)) {
        audit.add(AuditEntry(
          kind: r.kind,
          detail: r.detail,
          edgeState: r.edgeState,
          timeLabel: _time(r.createdAt.toIso8601String()),
        ));
      }
    } catch (_) {}

    try {
      momentCount = (await dao.listCapturedMoments(userId)).length;
      persisted = true;
    } catch (_) {}

    return DashboardData(
      ledger: ledger,
      riskMap: riskMap,
      audit: audit,
      momentCount: momentCount,
      persisted: persisted,
    );
  }

  String _time(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
