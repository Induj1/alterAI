import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alter_palette.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/premium_controls.dart';
import '../../../domain/entities/alter_models.dart';
import '../../shared/application/alter_data_providers.dart';

class SocialGraphScreen extends ConsumerWidget {
  const SocialGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(socialGraphProvider);
    final theme = Theme.of(context);

    return AmbientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'Social Graph',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Relationship intelligence for warm paths, NFC exchanges, and network compounding.',
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
                  height: context.isCompact ? 280 : 340,
                  child: const _GraphView(),
                ),
              ),
              const MetricTile(
                label: 'Warm paths',
                value: '18',
                icon: LucideIcons.network,
                accent: AlterPalette.iris,
              ),
              const MetricTile(
                label: 'NFC exchanges',
                value: '42',
                icon: LucideIcons.nfc,
                accent: AlterPalette.cyan,
              ),
              GlassPanel(
                onTap: () => context.go('/nfc'),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AlterPalette.coolGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(LucideIcons.nfc, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NFC Networking',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap exchange with match intelligence.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.58),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.route, size: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          contacts.when(
            data: (items) => ResponsiveGrid(
              mediumColumns: 2,
              expandedColumns: 2,
              children: [
                for (final contact in items) _ContactCard(contact: contact),
              ],
            ),
            loading: () => const GlassPanel(
              child: SizedBox(
                height: 170,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stackTrace) =>
                Text('Unable to load social graph: $error'),
          ),
        ],
      ),
    );
  }
}

class _GraphView extends StatelessWidget {
  const _GraphView();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GraphPainter(),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AlterPalette.coolGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SizedBox(
            width: 74,
            height: 74,
            child: Icon(LucideIcons.user, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.34;
    final nodes = List<Offset>.generate(8, (index) {
      final angle = (math.pi * 2 / 8) * index - math.pi / 2;
      final jitter = index.isEven ? 0.82 : 1.08;
      return Offset(
        center.dx + math.cos(angle) * radius * jitter,
        center.dy + math.sin(angle) * radius * jitter,
      );
    });

    final linePaint = Paint()
      ..color = AlterPalette.iris.withValues(alpha: 0.2)
      ..strokeWidth = 1.2;

    for (final node in nodes) {
      canvas.drawLine(center, node, linePaint);
    }
    for (var i = 0; i < nodes.length; i += 2) {
      canvas.drawLine(nodes[i], nodes[(i + 3) % nodes.length], linePaint);
    }
    for (final node in nodes) {
      canvas.drawCircle(
        node,
        10,
        Paint()..color = AlterPalette.iris.withValues(alpha: 0.14),
      );
      canvas.drawCircle(node, 4.5, Paint()..color = AlterPalette.iris);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final SocialContact contact;

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
                  color: AlterPalette.iris.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(LucideIcons.user, color: AlterPalette.iris),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      contact.context,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
                      ),
                    ),
                  ],
                ),
              ),
              PremiumChip(
                label: '${(contact.strength * 100).round()}%',
                selected: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in contact.tags) PremiumChip(label: tag),
            ],
          ),
        ],
      ),
    );
  }
}
