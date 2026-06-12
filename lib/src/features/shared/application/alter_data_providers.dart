import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/mock_alter_repository.dart';
import '../../../domain/entities/alter_models.dart';
import '../../../domain/repositories/alter_repository.dart';

final alterRepositoryProvider = Provider<AlterRepository>((ref) {
  return const MockAlterRepository();
});

final assistantBriefProvider = FutureProvider<AssistantBrief>((ref) {
  return ref.watch(alterRepositoryProvider).loadAssistantBrief();
});

final cloneCouncilProvider = FutureProvider<List<CloneAgent>>((ref) {
  return ref.watch(alterRepositoryProvider).loadCloneCouncil();
});

final futureScenariosProvider = FutureProvider<List<FutureScenario>>((ref) {
  return ref.watch(alterRepositoryProvider).loadFutureScenarios();
});

final opportunitySignalsProvider =
    FutureProvider<List<OpportunitySignal>>((ref) {
  return ref.watch(alterRepositoryProvider).loadOpportunitySignals();
});

final socialGraphProvider = FutureProvider<List<SocialContact>>((ref) {
  return ref.watch(alterRepositoryProvider).loadSocialGraph();
});

final reputationEventsProvider = FutureProvider<List<ReputationEvent>>((ref) {
  return ref.watch(alterRepositoryProvider).loadReputationEvents();
});

final lensInsightsProvider = FutureProvider<List<LensInsight>>((ref) {
  return ref.watch(alterRepositoryProvider).loadLensInsights();
});

