import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_state.dart';
import '../../../core/theme/alter_palette.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/premium_controls.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AmbientScaffold(
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        bottomPadding: 28,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GradientText(
                'ALTER',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: const [
                  _OnboardingPanel(
                    icon: LucideIcons.mic,
                    title: 'Speak your future into motion.',
                    body:
                        'Wake ALTER with Hey Alter, move across languages, and turn intent into action with a voice-first control layer.',
                    metric: '14 languages',
                  ),
                  _OnboardingPanel(
                    icon: LucideIcons.messages_square,
                    title: 'Think with your Clone Council.',
                    body:
                        'Strategist, Operator, Contrarian, and Connector clones debate plans before you commit your time.',
                    metric: '4 active clones',
                  ),
                  _OnboardingPanel(
                    icon: LucideIcons.radar,
                    title: 'Find the signal before it is obvious.',
                    body:
                        'Opportunity Radar combines memory, social graph, web signals, NFC, and reputation to reveal your next best move.',
                    metric: '94% top signal',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (var index = 0; index < 3; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    margin: const EdgeInsets.only(right: 8),
                    height: 8,
                    width: _page == index ? 30 : 8,
                    decoration: BoxDecoration(
                      color: _page == index
                          ? AlterPalette.iris
                          : theme.colorScheme.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                const Spacer(),
                PremiumButton(
                  compact: true,
                  label: _page == 2 ? 'Begin' : 'Next',
                  icon: LucideIcons.arrow_right,
                  onPressed: () {
                    if (_page < 2) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                      );
                      return;
                    }
                    ref
                        .read(alterAppControllerProvider.notifier)
                        .completeOnboarding();
                    context.go('/voice');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.metric,
  });

  final IconData icon;
  final String title;
  final String body;
  final String metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: GlassPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AlterPalette.premiumGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
              ),
            ),
            const SizedBox(height: 24),
            PremiumChip(label: metric, selected: true, icon: LucideIcons.check),
          ],
        ),
      ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.06),
    );
  }
}

