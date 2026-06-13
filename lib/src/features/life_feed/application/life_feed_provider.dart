import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_provider.dart';
import '../../profile/application/profile_provider.dart';
import '../../shared/application/alter_data_providers.dart';
import '../data/life_feed_api_client.dart';
import '../domain/life_feed_models.dart';

final lifeFeedApiClientProvider = Provider<LifeFeedApiClient>((ref) {
  const baseUrl = String.fromEnvironment('ALTER_API_GATEWAY_URL');
  final client = LifeFeedApiClient(baseUrl: baseUrl);
  ref.onDispose(client.close);
  return client;
});

final lifeFeedProvider = FutureProvider<LifeFeedSnapshot>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return LifeFeedSnapshot.fallback();
  }

  final profile = ref.watch(userProfileProvider).asData?.value;
  final firstName = _firstName(profile?.displayName ?? user.email ?? 'there');

  final api = ref.watch(lifeFeedApiClientProvider);
  final remote = await api.fetch(userId: user.id);
  if (remote != null) {
    return remote;
  }

  final brief = await ref.watch(assistantBriefProvider.future);
  final opportunities = await ref.watch(opportunitySignalsProvider.future);

  final now = DateTime.now();
  final weekday = _weekday(now.weekday);
  final month = _month(now.month);

  return LifeFeedSnapshot(
    greeting: brief.greeting.isNotEmpty ? brief.greeting : 'Good morning, $firstName.',
    dateSummary:
        '$weekday, ${now.day} $month · ${brief.signals.length} things need you today',
    focusTitle: brief.focus.isNotEmpty ? brief.focus : brief.nextAction,
    focusRationale: brief.nextAction.isNotEmpty
        ? brief.nextAction
        : 'Doing it this morning cuts next week\'s overload by ~40%.',
    itemsNeedingAttention: brief.signals.length,
    opportunities: opportunities.take(3).map((o) {
      return LifeFeedOpportunity(
        tag: o.category.toUpperCase(),
        matchScore: o.score.round(),
        title: o.title,
        meta: '${o.window} · ${o.source}',
      );
    }).toList(),
    tasks: brief.signals.asMap().entries.map((entry) {
      final i = entry.key;
      final signal = entry.value;
      return LifeFeedTask(
        title: signal,
        meta: i == 0 ? 'Today · priority' : 'Pending',
        badge: i == 0 ? 'Now' : '${i + 1}pm',
        hot: i == 1,
        done: i == 0 && brief.signals.length > 2,
      );
    }).toList(),
  );
});

String _firstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'there';
  return trimmed.split(RegExp(r'\s+')).first.replaceAll('.', '');
}

String _weekday(int day) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[(day - 1).clamp(0, 6)];
}

String _month(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[(month - 1).clamp(0, 11)];
}
