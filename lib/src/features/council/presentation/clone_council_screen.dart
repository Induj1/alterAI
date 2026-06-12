import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class CloneCouncilScreen extends ConsumerWidget {
  const CloneCouncilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(cloneCouncilProvider);
    final theme = Theme.of(context);

    return AmbientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'Clone Council',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Multi-agent reasoning with consensus, dissent, and next action traceability.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          const ResponsiveGrid(
            mediumColumns: 3,
            expandedColumns: 3,
            children: [
              MetricTile(
                label: 'Council consensus',
                value: '86%',
                icon: LucideIcons.messages_square,
                accent: AlterPalette.iris,
              ),
              MetricTile(
                label: 'Open dissent',
                value: '2',
                icon: LucideIcons.scale,
                accent: AlterPalette.aura,
              ),
              MetricTile(
                label: 'Action quality',
                value: 'A-',
                icon: LucideIcons.shield_check,
                accent: AlterPalette.mint,
              ),
            ],
          ),
          const SizedBox(height: 18),
          agents.when(
            data: (items) => ResponsiveGrid(
              mediumColumns: 2,
              expandedColumns: 2,
              children: [
                for (final agent in items)
                  _AgentCard(agent: agent)
                      .animate()
                      .fadeIn(duration: 360.ms)
                      .slideY(begin: 0.04),
              ],
            ),
            loading: () => const GlassPanel(
              child: SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stackTrace) => Text('Unable to load council: $error'),
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Council output',
                  subtitle:
                      'The council recommends a narrow premium beta, one paid pilot, and a network-first launch sequence.',
                  trailing: PremiumChip(
                    label: 'Consensus',
                    selected: true,
                    icon: LucideIcons.check,
                  ),
                ),
                const SizedBox(height: 18),
                _DecisionStep(
                  number: '01',
                  title: 'Use NFC graph to recruit 12 ideal founders.',
                  color: AlterPalette.cyan,
                ),
                _DecisionStep(
                  number: '02',
                  title: 'Convert one OfficeKit workflow into a paid pilot.',
                  color: AlterPalette.iris,
                ),
                _DecisionStep(
                  number: '03',
                  title: 'Publish reputation-backed outcomes after week two.',
                  color: AlterPalette.aura,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({required this.agent});

  final CloneAgent agent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: agent.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Icon(LucideIcons.bot, color: agent.accent, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      agent.role,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
                      ),
                    ),
                  ],
                ),
              ),
              PremiumChip(label: agent.state, selected: true),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            agent.summary,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: agent.confidence,
              minHeight: 7,
              backgroundColor: agent.accent.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(agent.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionStep extends StatelessWidget {
  const _DecisionStep({
    required this.number,
    required this.title,
    required this.color,
  });

  final String number;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Text(
                  number,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

