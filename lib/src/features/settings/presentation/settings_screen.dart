import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_state.dart';
import '../../../core/theme/alter_palette.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/premium_controls.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alterAppControllerProvider);
    final controller = ref.read(alterAppControllerProvider.notifier);
    final theme = Theme.of(context);

    return AmbientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'Settings',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tune theme, privacy, model stack, voice preferences, and connected systems.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ResponsiveGrid(
            mediumColumns: 2,
            expandedColumns: 3,
            children: const [
              MetricTile(
                label: 'Model routing',
                value: 'Gemini 2.5',
                icon: LucideIcons.brain_circuit,
                accent: AlterPalette.iris,
              ),
              MetricTile(
                label: 'Memory vault',
                value: 'Locked',
                icon: LucideIcons.lock,
                accent: AlterPalette.mint,
              ),
              MetricTile(
                label: 'Latency target',
                value: '<300 ms',
                icon: LucideIcons.zap,
                accent: AlterPalette.cyan,
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Appearance',
                  subtitle: 'Use system theme or force a precise mode.',
                ),
                const SizedBox(height: 16),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(LucideIcons.monitor),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(LucideIcons.sun),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(LucideIcons.moon),
                    ),
                  ],
                  selected: {state.themeMode},
                  onSelectionChanged: (selection) {
                    controller.setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ResponsiveGrid(
            mediumColumns: 2,
            expandedColumns: 2,
            children: [
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Privacy',
                      subtitle: 'Agent actions stay permissioned and auditable.',
                    ),
                    const SizedBox(height: 14),
                    _SwitchRow(
                      icon: LucideIcons.shield_check,
                      title: 'Privacy shield',
                      subtitle: 'Require confirmation before external actions.',
                      value: state.privacyShield,
                      onChanged: controller.setPrivacyShield,
                    ),
                    _SwitchRow(
                      icon: LucideIcons.bell,
                      title: 'Proactive briefs',
                      subtitle: 'Let ALTER prepare daily next-move briefings.',
                      value: state.proactiveBriefs,
                      onChanged: controller.setProactiveBriefs,
                    ),
                  ],
                ),
              ),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Connected systems',
                      subtitle: 'Production adapters are ready to replace mocks.',
                    ),
                    const SizedBox(height: 14),
                    const _SystemRow('Supabase', 'Auth, Postgres, Storage'),
                    const _SystemRow('Neo4j', 'Personal and social graph'),
                    const _SystemRow('Qdrant', 'Semantic memory search'),
                    const _SystemRow('Firecrawl', 'Opportunity discovery'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AlterPalette.iris.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: AlterPalette.iris, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SystemRow extends StatelessWidget {
  const _SystemRow(this.name, this.detail);

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(LucideIcons.check, color: AlterPalette.mint, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

