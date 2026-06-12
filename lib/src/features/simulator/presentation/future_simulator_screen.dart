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

class FutureSimulatorScreen extends ConsumerStatefulWidget {
  const FutureSimulatorScreen({super.key});

  @override
  ConsumerState<FutureSimulatorScreen> createState() =>
      _FutureSimulatorScreenState();
}

class _FutureSimulatorScreenState extends ConsumerState<FutureSimulatorScreen> {
  double _riskTolerance = 0.62;
  double _timeHorizon = 0.48;

  @override
  Widget build(BuildContext context) {
    final scenarios = ref.watch(futureScenariosProvider);
    final theme = Theme.of(context);

    return AmbientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'Future Simulator',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Model alternate paths using memory, social graph, opportunities, and council assumptions.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ResponsiveGrid(
            mediumColumns: 2,
            expandedColumns: 4,
            children: const [
              MetricTile(
                label: 'Scenario runs',
                value: '128',
                icon: LucideIcons.route,
                accent: AlterPalette.iris,
              ),
              MetricTile(
                label: 'Best upside',
                value: '3.4x',
                icon: LucideIcons.chart_no_axes_combined,
                accent: AlterPalette.mint,
              ),
              MetricTile(
                label: 'Risk delta',
                value: '-18%',
                icon: LucideIcons.scale,
                accent: AlterPalette.aura,
              ),
              MetricTile(
                label: 'Confidence',
                value: '71%',
                icon: LucideIcons.shield_check,
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
                  title: 'Simulation controls',
                  subtitle: 'Tune the assumptions before the council reruns.',
                ),
                const SizedBox(height: 18),
                _SliderRow(
                  label: 'Risk tolerance',
                  value: _riskTolerance,
                  onChanged: (value) => setState(() => _riskTolerance = value),
                ),
                _SliderRow(
                  label: 'Time horizon',
                  value: _timeHorizon,
                  onChanged: (value) => setState(() => _timeHorizon = value),
                ),
                const SizedBox(height: 14),
                PremiumButton(
                  label: 'Run simulation',
                  icon: LucideIcons.sparkles,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          scenarios.when(
            data: (items) => ResponsiveGrid(
              mediumColumns: 2,
              expandedColumns: 3,
              children: [
                for (final scenario in items) _ScenarioCard(scenario: scenario),
              ],
            ),
            loading: () => const GlassPanel(
              child: SizedBox(
                height: 170,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stackTrace) =>
                Text('Unable to load scenarios: $error'),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AlterPalette.iris,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario});

  final FutureScenario scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumChip(
            label: scenario.horizon,
            selected: true,
            icon: LucideIcons.clock,
          ),
          const SizedBox(height: 18),
          Text(
            scenario.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            scenario.upside,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: scenario.probability,
              minHeight: 8,
              backgroundColor: AlterPalette.iris.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AlterPalette.iris,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            scenario.risk,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              height: 1.38,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final lever in scenario.levers) PremiumChip(label: lever),
            ],
          ),
        ],
      ),
    );
  }
}

