import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/supabase_alter_repository.dart';
import '../../../domain/entities/alter_models.dart';
import '../../../domain/repositories/alter_repository.dart';
import '../../auth/application/auth_provider.dart';
import '../../backend/application/backend_config_controller.dart';
import '../../backend/data/backend_feature_api_client.dart';
import '../../profile/application/profile_provider.dart';

final alterRepositoryProvider = Provider<AlterRepository>((ref) {
  return SupabaseAlterRepository(Supabase.instance.client);
});

final assistantBriefProvider = FutureProvider<AssistantBrief>((ref) {
  return ref.watch(alterRepositoryProvider).loadAssistantBrief();
});

final cloneCouncilProvider = FutureProvider<List<CloneAgent>>((ref) async {
  final config = await ref.watch(backendConfigProvider.future);
  final client = _featureClient(config, BackendService.cloneCouncil);
  if (client != null) {
    try {
      final agents = await client.fetchCloneAgents();
      client.close();
      if (agents.isNotEmpty) return agents;
    } catch (_) {
      client.close();
    }
  }
  return ref.watch(alterRepositoryProvider).loadCloneCouncil();
});

final futureScenariosProvider = FutureProvider<List<FutureScenario>>((
  ref,
) async {
  final config = await ref.watch(backendConfigProvider.future);
  final profile = ref.watch(userProfileProvider).asData?.value;
  final client = _featureClient(config, BackendService.futureSimulation);
  if (client != null) {
    try {
      final scenarios = await client.simulateFutures(profile: profile);
      client.close();
      if (scenarios.isNotEmpty) return scenarios;
    } catch (_) {
      client.close();
    }
  }
  return ref.watch(alterRepositoryProvider).loadFutureScenarios();
});

final opportunitySignalsProvider = FutureProvider<List<OpportunitySignal>>((
  ref,
) async {
  final config = await ref.watch(backendConfigProvider.future);
  final profile = ref.watch(userProfileProvider).asData?.value;
  final client = _featureClient(config, BackendService.opportunityEngine);
  if (client != null) {
    try {
      final opportunities = await client.fetchOpportunities(profile: profile);
      client.close();
      if (opportunities.isNotEmpty) return opportunities;
    } catch (_) {
      client.close();
    }
  }
  return ref.watch(alterRepositoryProvider).loadOpportunitySignals();
});

final socialGraphProvider = FutureProvider<List<SocialContact>>((ref) {
  return ref.watch(alterRepositoryProvider).loadSocialGraph();
});

final reputationEventsProvider = FutureProvider<List<ReputationEvent>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const <ReputationEvent>[];
  final config = await ref.watch(backendConfigProvider.future);
  final client = _featureClient(config, BackendService.reputationEngine);
  if (client != null) {
    try {
      final events = await client.fetchReputationEvents(userId: user.id);
      client.close();
      if (events.isNotEmpty) return events;
    } catch (_) {
      client.close();
    }
  }
  return ref.watch(alterRepositoryProvider).loadReputationEvents();
});

final lensInsightsProvider = FutureProvider<List<LensInsight>>((ref) {
  return ref.watch(alterRepositoryProvider).loadLensInsights();
});

BackendFeatureApiClient? _featureClient(
  BackendConfig config,
  BackendService service,
) {
  if (!config.hasGateway) return null;
  final url = config.serviceUrl(service);
  if (url.isEmpty) return null;
  return BackendFeatureApiClient(
    baseUrl: url,
    timeout: const Duration(seconds: 5),
  );
}
