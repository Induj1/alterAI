import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../auth/application/auth_provider.dart';
import '../../backend/application/backend_config_controller.dart';
import '../../shared/application/alter_data_providers.dart';

const _reputationTimeout = Duration(seconds: 4);

class ReputationScoreSnapshot {
  const ReputationScoreSnapshot({
    required this.score,
    required this.recentDelta,
    required this.topDomain,
    required this.topDomainFit,
    required this.focusArea,
    required this.focusAreaFit,
  });

  final int score;
  final int recentDelta;
  final String topDomain;
  final int topDomainFit;
  final String focusArea;
  final int focusAreaFit;
}

final reputationScoreProvider = FutureProvider<ReputationScoreSnapshot>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const ReputationScoreSnapshot(
      score: 78,
      recentDelta: 6,
      topDomain: 'AI Engineering',
      topDomainFit: 92,
      focusArea: 'System Design',
      focusAreaFit: 54,
    );
  }

  final config = await ref.watch(backendConfigProvider.future);
  if (config.hasGateway) {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${config.gatewayUrl}/v1/reputation/users/${user.id}/score',
            ),
          )
          .timeout(_reputationTimeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final strengths = (json['strengths'] as List<dynamic>? ?? const [])
            .cast<String>();
        final risks = (json['risks'] as List<dynamic>? ?? const [])
            .cast<String>();
        return ReputationScoreSnapshot(
          score: json['score'] as int? ?? 78,
          recentDelta: json['recent_delta'] as int? ?? 0,
          topDomain: strengths.isNotEmpty ? strengths.first : 'AI Engineering',
          topDomainFit: 92,
          focusArea: risks.isNotEmpty ? risks.first : 'System Design',
          focusAreaFit: 54,
        );
      }
    } catch (_) {}
  }

  final events = await ref.watch(reputationEventsProvider.future);
  final score =
      70 + events.fold<int>(0, (sum, e) => sum + e.delta).clamp(-20, 28);
  return ReputationScoreSnapshot(
    score: score,
    recentDelta: events.isEmpty
        ? 0
        : events.take(5).fold<int>(0, (sum, e) => sum + e.delta),
    topDomain: 'AI Engineering',
    topDomainFit: 92,
    focusArea: 'System Design',
    focusAreaFit: 54,
  );
});
