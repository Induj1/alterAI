import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/agent/presentation/agent_screen.dart';
import '../features/agent/presentation/live_feed_screen.dart';
import '../features/backend/presentation/council_os_screen.dart';
import '../features/backend/presentation/future_sim_os_screen.dart';
import '../features/backend/presentation/life_feed_os_screen.dart';
import '../features/backend/presentation/opportunity_os_screen.dart';
import '../features/auth/application/auth_provider.dart';
import '../features/backend/presentation/backend_feature_hub_screen.dart';
import '../features/contextos/presentation/context_mission_control_screen.dart';
import '../features/contextos/presentation/contextos_home_screen.dart';
import '../features/contextos/presentation/daytwin_screen.dart';
import '../features/contextos/presentation/decision_council_screen.dart';
import '../features/contextos/presentation/decision_dna_screen.dart';
import '../features/contextos/presentation/digital_twin_screen.dart';
import '../features/contextos/presentation/edge_model_screen.dart';
import '../features/contextos/presentation/futuretwin_screen.dart';
import '../features/contextos/presentation/lifeshield_screen.dart';
import '../features/contextos/presentation/memory_screen.dart';
import '../features/contextos/presentation/openclaw_queue_screen.dart';
import '../features/contextos/presentation/privacy_screen.dart';
import '../features/council/presentation/clone_council_screen.dart';
import '../features/lens/presentation/alter_lens_screen.dart';
import '../features/mission/presentation/mission_control_screen.dart';
import '../features/nfc/presentation/nfc_networking_screen.dart';
import '../features/opportunity/presentation/opportunity_radar_screen.dart';
import '../features/permissions/presentation/permission_hub_screen.dart';
import '../features/profile/application/profile_provider.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/reputation/presentation/reputation_dashboard_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/simulator/presentation/future_simulator_screen.dart';
import '../features/social/presentation/social_graph_screen.dart';
import '../features/voice/presentation/voice_assistant_screen.dart';
import '../ui/routes.dart';
import '../ui/screens/ftue.dart';
import '../ui/screens/onboarding.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = AuthChangeNotifier();
  ref.listen(userProfileProvider, (previous, next) => notifier.refresh());
  ref.onDispose(notifier.dispose);

  return GoRouter(
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final path = state.uri.path;
      final profile = ref.read(userProfileProvider).asData?.value;
      final onboardingDone = profile?.onboardingDone == true;

      if (user == null) {
        if (path == AlterRoutes.home ||
            path == AlterRoutes.languages ||
            path == AlterRoutes.about ||
            path == AlterRoutes.permissions) {
          return AlterRoutes.login;
        }
        return null;
      }

      if (path == AlterRoutes.login ||
          path == AlterRoutes.ftueWhat ||
          path == AlterRoutes.features ||
          path == AlterRoutes.getStarted) {
        return onboardingDone ? AlterRoutes.agent : AlterRoutes.permissions;
      }

      if (path == AlterRoutes.permissions) {
        return null;
      }

      if (path == AlterRoutes.languages || path == AlterRoutes.about) {
        if (onboardingDone) {
          return AlterRoutes.agent;
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AlterRoutes.ftueWhat,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const FtueWhatScreen()),
      ),
      GoRoute(
        path: AlterRoutes.features,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const FeaturePagesScreen()),
      ),
      GoRoute(
        path: AlterRoutes.getStarted,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const GetStartedScreen()),
      ),
      GoRoute(
        path: AlterRoutes.login,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: AlterRoutes.permissions,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const PermissionHubScreen()),
      ),
      GoRoute(
        path: AlterRoutes.languages,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const LanguagesScreen()),
      ),
      GoRoute(
        path: AlterRoutes.about,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const AboutYouScreen()),
      ),
      GoRoute(
        path: AlterRoutes.home,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const ContextOsHomeScreen()),
      ),
      GoRoute(
        path: AlterRoutes.backend,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const BackendFeatureHubScreen(),
        ),
      ),
      GoRoute(
        path: '${AlterRoutes.backend}/:serviceId',
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: BackendServiceDetailScreen(
            serviceId: state.pathParameters['serviceId'] ?? 'api-gateway',
          ),
        ),
      ),
      GoRoute(
        path: AlterRoutes.settings,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: AlterRoutes.profile,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const ProfileSetupScreen()),
      ),
      GoRoute(
        path: AlterRoutes.voice,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const VoiceAssistantScreen()),
      ),
      GoRoute(
        path: AlterRoutes.feed,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const LiveFeedScreen()),
      ),
      GoRoute(
        path: '/lifefeed',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const LifeFeedOsScreen()),
      ),
      GoRoute(
        path: '/sim',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const FutureSimOsScreen()),
      ),
      GoRoute(
        path: '/clones',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const CouncilOsScreen()),
      ),
      GoRoute(
        path: '/opps',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const OpportunityOsScreen()),
      ),
      GoRoute(
        path: AlterRoutes.contextos,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const ContextOsHomeScreen()),
      ),
      GoRoute(
        path: AlterRoutes.twin,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DigitalTwinScreen()),
      ),
      GoRoute(
        path: AlterRoutes.shield,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const LifeShieldScreen()),
      ),
      GoRoute(
        path: AlterRoutes.dayTwin,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DayTwinScreen()),
      ),
      GoRoute(
        path: AlterRoutes.futureTwin,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const FutureTwinScreen()),
      ),
      GoRoute(
        path: AlterRoutes.decisionCouncil,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DecisionCouncilScreen()),
      ),
      GoRoute(
        path: AlterRoutes.decisionDna,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DecisionDnaScreen()),
      ),
      GoRoute(
        path: AlterRoutes.memory,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const MemoryScreen()),
      ),
      GoRoute(
        path: AlterRoutes.edge,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const EdgeModelScreen()),
      ),
      GoRoute(
        path: AlterRoutes.mission,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const MissionControlScreen()),
      ),
      GoRoute(
        path: AlterRoutes.officeKit,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const ContextMissionControlScreen(),
        ),
      ),
      GoRoute(
        path: AlterRoutes.privacy,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const PrivacyScreen()),
      ),
      GoRoute(
        path: AlterRoutes.reputation,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const ReputationDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AlterRoutes.council,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const CloneCouncilScreen()),
      ),
      GoRoute(
        path: AlterRoutes.simulator,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const FutureSimulatorScreen()),
      ),
      GoRoute(
        path: AlterRoutes.radar,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const OpportunityRadarScreen(),
        ),
      ),
      GoRoute(
        path: AlterRoutes.social,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const SocialGraphScreen()),
      ),
      GoRoute(
        path: AlterRoutes.deepAnalysis,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const MissionControlScreen()),
      ),
      GoRoute(
        path: AlterRoutes.lens,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const AlterLensScreen()),
      ),
      GoRoute(
        path: AlterRoutes.nfc,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const NfcNetworkingScreen()),
      ),
      GoRoute(
        path: AlterRoutes.openclaw,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const OpenClawQueueScreen()),
      ),
      GoRoute(
        path: AlterRoutes.agent,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const AgentScreen()),
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
