import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/alter_palette.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        context.go('/permissions');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AmbientScaffold(
        scrollable: false,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GradientBorderPanel(
                    child: GlassPanel(
                      padding: const EdgeInsets.all(22),
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 42,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2100.ms, color: Colors.white54)
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: 700.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 26),
              GradientText(
                'ALTER',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ).animate().fadeIn(duration: 520.ms).slideY(begin: 0.18),
              const SizedBox(height: 10),
              Text(
                'Voice-first AI Future Operating System',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 180.ms, duration: 520.ms),
              const SizedBox(height: 34),
              SizedBox(
                width: 172,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    backgroundColor: AlterPalette.iris.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AlterPalette.iris,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 340.ms),
            ],
          ),
        ),
      ),
    );
  }
}
