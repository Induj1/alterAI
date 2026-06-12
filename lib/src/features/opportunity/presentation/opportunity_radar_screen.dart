import 'dart:math' as math;

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

class OpportunityRadarScreen extends ConsumerWidget {
  const OpportunityRadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(opportunitySignalsProvider);
    final theme = Theme.of(context);

    return AmbientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'Opportunity Radar',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Live signal discovery across web, memory, social graph, and office context.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ResponsiveGrid(
            mediumColumns: 2,
            expandedColumns: 3,
            children: [
              GlassPanel(
                padding: EdgeInsets.zero,
                child: SizedBox(
                  height: context.isCompact ? 260 : 330,
                  child: const _RadarView(),
                ),
              ),
              const MetricTile(
                label: 'Heat score',
                value: '94',
                icon: LucideIcons.radar,
                detail: 'Partnership lane is peaking',
                accent: AlterPalette.aura,
              ),
              const MetricTile(
                label: 'Fresh sources',
                value: '37',
                icon: LucideIcons.globe,
                detail: 'Firecrawl and social graph inputs',
                accent: AlterPalette.cyan,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _OpportunityHeatmap(),
          const SizedBox(height: 18),
          opportunities.when(
            data: (items) => Column(
              children: [
                for (final opportunity in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OpportunityCard(opportunity: opportunity),
                  ),
              ],
            ),
            loading: () => const GlassPanel(
              child: SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stackTrace) =>
                Text('Unable to load opportunities: $error'),
          ),
        ],
      ),
    );
  }
}

class _OpportunityHeatmap extends StatelessWidget {
  const _OpportunityHeatmap();

  @override
  Widget build(BuildContext context) {
    final cells = const [
      ('AI ops', 0.94, AlterPalette.aura),
      ('Events', 0.87, AlterPalette.iris),
      ('OfficeKit', 0.78, AlterPalette.cyan),
      ('Enterprise', 0.69, AlterPalette.mint),
      ('Creator', 0.44, AlterPalette.amber),
      ('Hiring', 0.36, AlterPalette.danger),
    ];

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Opportunity heatmap',
            subtitle: 'Weighted by intent velocity, network fit, and timing.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final width = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final cell in cells)
                    SizedBox(
                      width: width,
                      child: _HeatCell(
                        label: cell.$1,
                        value: cell.$2,
                        color: cell.$3,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09 + value * 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '${(value * 100).round()}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarView extends StatelessWidget {
  const _RadarView();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarPainter(),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AlterPalette.premiumGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(LucideIcons.radar, color: Colors.white, size: 34),
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 2400.ms,
          color: Colors.white.withValues(alpha: 0.28),
        );
  }
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AlterPalette.iris.withValues(alpha: 0.24);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AlterPalette.iris.withValues(alpha: 0),
          AlterPalette.iris.withValues(alpha: 0.28),
          AlterPalette.cyan.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, ringPaint);
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi / 1.55,
      true,
      sweepPaint,
    );

    final points = [
      Offset(center.dx + radius * 0.42, center.dy - radius * 0.34),
      Offset(center.dx - radius * 0.58, center.dy + radius * 0.12),
      Offset(center.dx + radius * 0.18, center.dy + radius * 0.64),
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.52),
    ];

    for (final point in points) {
      canvas.drawCircle(
        point,
        6,
        Paint()..color = AlterPalette.aura.withValues(alpha: 0.92),
      );
      canvas.drawCircle(
        point,
        14,
        Paint()..color = AlterPalette.aura.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity});

  final OpportunitySignal opportunity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              PremiumChip(
                label: '${(opportunity.score * 100).round()}',
                selected: true,
                icon: LucideIcons.zap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            opportunity.evidence,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: opportunity.score,
              minHeight: 8,
              backgroundColor: AlterPalette.aura.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AlterPalette.aura),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PremiumChip(label: opportunity.category),
              PremiumChip(label: opportunity.source, icon: LucideIcons.globe),
              PremiumChip(label: opportunity.window, icon: LucideIcons.clock),
            ],
          ),
        ],
      ),
    );
  }
}
