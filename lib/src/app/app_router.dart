import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/council/presentation/clone_council_screen.dart';
import '../features/home/presentation/main_shell.dart';
import '../features/lens/presentation/alter_lens_screen.dart';
import '../features/mission/presentation/mission_control_screen.dart';
import '../features/nfc/presentation/nfc_networking_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/opportunity/presentation/opportunity_radar_screen.dart';
import '../features/reputation/presentation/reputation_dashboard_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/simulator/presentation/future_simulator_screen.dart';
import '../features/social/presentation/social_graph_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/voice/presentation/voice_assistant_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/mission',
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
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const SocialGraphScreen(),
            ),
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
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const AlterLensScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const SettingsScreen(),
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
