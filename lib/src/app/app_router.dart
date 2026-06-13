import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/agent/presentation/agent_screen.dart';
import '../features/agent/presentation/live_feed_screen.dart';
import '../features/auth/application/auth_provider.dart'
    show AuthChangeNotifier;
import '../features/auth/presentation/login_screen.dart';
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
import '../features/home/presentation/main_shell.dart';
import '../features/lens/presentation/alter_lens_screen.dart';
import '../features/mission/presentation/mission_control_screen.dart';
import '../features/nfc/presentation/nfc_networking_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/opportunity/presentation/opportunity_radar_screen.dart';
import '../features/permissions/presentation/permission_hub_screen.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/reputation/presentation/reputation_dashboard_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/simulator/presentation/future_simulator_screen.dart';
import '../features/social/presentation/social_graph_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/voice/presentation/voice_assistant_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = AuthChangeNotifier();
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final path = state.uri.path;
      if (path == '/splash') return null;
      if (user == null && path != '/login') return '/login';
      if (user != null && path == '/login') return '/permissions';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: '/permissions',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const PermissionHubScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/agent',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const AgentScreen()),
          ),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const ContextOsHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/twin',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const DigitalTwinScreen()),
          ),
          GoRoute(
            path: '/feed',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const LiveFeedScreen()),
          ),
          GoRoute(
            path: '/shield',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const LifeShieldScreen()),
          ),
          GoRoute(
            path: '/daytwin',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const DayTwinScreen()),
          ),
          GoRoute(
            path: '/futuretwin',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const FutureTwinScreen()),
          ),
          GoRoute(
            path: '/openclaw',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const OpenClawQueueScreen(),
            ),
          ),
          GoRoute(
            path: '/dna',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const DecisionDnaScreen()),
          ),
          GoRoute(
            path: '/decision-council',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const DecisionCouncilScreen(),
            ),
          ),
          GoRoute(
            path: '/memory',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const MemoryScreen()),
          ),
          GoRoute(
            path: '/edge',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const EdgeModelScreen()),
          ),
          GoRoute(
            path: '/privacy',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const PrivacyScreen()),
          ),
          GoRoute(
            path: '/mission',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const ContextMissionControlScreen(),
            ),
          ),
          GoRoute(
            path: '/officekit',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const MissionControlScreen(),
            ),
          ),
          GoRoute(
            path: '/voice',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const VoiceAssistantScreen(),
            ),
          ),
          GoRoute(
            path: '/council',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const CloneCouncilScreen(),
            ),
          ),
          GoRoute(
            path: '/simulator',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const FutureSimulatorScreen(),
            ),
          ),
          GoRoute(
            path: '/radar',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const OpportunityRadarScreen(),
            ),
          ),
          GoRoute(
            path: '/social',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const SocialGraphScreen()),
          ),
          GoRoute(
            path: '/nfc',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const NfcNetworkingScreen(),
            ),
          ),
          GoRoute(
            path: '/reputation',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const ReputationDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/lens',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const AlterLensScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _fadePage(key: state.pageKey, child: const SettingsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const ProfileSetupScreen(),
            ),
          ),
        ],
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
