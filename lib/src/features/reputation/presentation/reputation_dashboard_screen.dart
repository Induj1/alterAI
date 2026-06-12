import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/alter_palette.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/premium_controls.dart';
import '../../../domain/entities/alter_models.dart';
import '../../shared/application/alter_data_providers.dart';

class ReputationDashboardScreen extends ConsumerWidget {
  const ReputationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(reputationEventsProvider);
    final theme = Theme.of(context);

    return AmbientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'Reputation Dashboard',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track trust, responsiveness, delivery, and relationship quality as durable assets.',
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
              _ReputationScore(),
              MetricTile(
                label: 'Trust trend',
                value: '+26',
                icon: LucideIcons.trending_up,
                accent: AlterPalette.mint,
              ),
              MetricTile(
                label: 'Recovery items',
                value: '1',
                icon: LucideIcons.bell,
                accent: AlterPalette.amber,
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Reputation vector',
                  subtitle: 'Signals are weighted by recency, trust, and impact.',
                ),
                const SizedBox(height: 18),
                _Bar(label: 'Reliability', value: 0.91, color: AlterPalette.mint),
                _Bar(label: 'Follow-through', value: 0.84, color: AlterPalette.iris),
                _Bar(label: 'Generosity', value: 0.77, color: AlterPalette.cyan),
                _Bar(label: 'Visibility', value: 0.68, color: AlterPalette.aura),
              ],
            ),
          ),
          const SizedBox(height: 18),
          events.when(
            data: (items) => Column(
              children: [
                for (final event in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EventCard(event: event),
                  ),
              ],
            ),
            loading: () => const GlassPanel(
              child: SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stackTrace) =>
                Text('Unable to load reputation: $error'),
          ),
        ],
      ),
    );
  }
}

class _ReputationScore extends StatelessWidget {
  const _ReputationScore();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumChip(
            label: 'Live score',
            selected: true,
            icon: LucideIcons.trophy,
          ),
          const SizedBox(height: 20),
          GradientText(
            '842',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'High trust operator',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final ReputationEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = event.delta >= 0;
    final color = positive ? AlterPalette.mint : AlterPalette.danger;
    return GlassPanel(
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: 54,
              height: 54,
              child: Center(
                child: Text(
                  positive ? '+${event.delta}' : '${event.delta}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            event.timestamp,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

