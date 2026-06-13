import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/agent/presentation/agent_screen.dart';
import '../features/auth/application/auth_provider.dart';
import '../features/contextos/presentation/openclaw_queue_screen.dart';
import '../features/lens/presentation/alter_lens_screen.dart';
import '../features/nfc/presentation/nfc_networking_screen.dart';
import '../features/permissions/presentation/permission_hub_screen.dart';
import '../features/profile/application/profile_provider.dart';
import '../ui/routes.dart';
import '../ui/screens/deep.dart';
import '../ui/screens/ftue.dart';
import '../ui/screens/main_shell.dart';
import '../ui/screens/onboarding.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = AuthChangeNotifier();
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AlterRoutes.ftueWhat,
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final path = state.uri.path;

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
        return AlterRoutes.permissions;
      }

      if (path == AlterRoutes.permissions) {
        return null;
      }

      if (path == AlterRoutes.languages || path == AlterRoutes.about) {
        final profile = ref.read(userProfileProvider).asData?.value;
        if (profile?.onboardingDone == true) {
          return AlterRoutes.home;
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
            _fadePage(key: state.pageKey, child: const MainShell()),
      ),
      GoRoute(
        path: AlterRoutes.council,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const CloneCouncilScreen()),
      ),
      GoRoute(
        path: AlterRoutes.simulator,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const FutureSimulatorScreen(),
        ),
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
            _fadePage(key: state.pageKey, child: const DeepAnalysisScreen()),
      ),
      GoRoute(
        path: AlterRoutes.lens,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const AlterLensScreen()),
      ),
      GoRoute(
        path: AlterRoutes.nfc,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const NfcNetworkingScreen(),
        ),
      ),
      GoRoute(
        path: AlterRoutes.openclaw,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const OpenClawQueueScreen(),
        ),
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
