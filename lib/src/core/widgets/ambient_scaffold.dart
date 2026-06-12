import 'package:flutter/material.dart';

import '../theme/alter_palette.dart';
import '../utils/responsive.dart';

class AmbientScaffold extends StatelessWidget {
  const AmbientScaffold({
    required this.child,
    this.padding,
    this.scrollable = true,
    this.bottomPadding = 104,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pagePadding = padding ??
        EdgeInsets.fromLTRB(
          context.pageGutter,
          18,
          context.pageGutter,
          bottomPadding,
        );

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.maxContentWidth),
        child: Padding(
          padding: pagePadding,
          child: child,
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  AlterPalette.ink,
                  Color(0xFF151125),
                  Color(0xFF070911),
                ]
              : const [
                  AlterPalette.white,
                  Color(0xFFF4F1FF),
                  Color(0xFFEAF9FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AmbientPatternPainter(isDark: isDark),
            ),
          ),
          if (scrollable)
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: content),
              ],
            )
          else
            content,
        ],
      ),
    );
  }
}

class _AmbientPatternPainter extends CustomPainter {
  const _AmbientPatternPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AlterPalette.iris.withValues(alpha: isDark ? 0.22 : 0.16),
          AlterPalette.cyan.withValues(alpha: isDark ? 0.12 : 0.18),
          AlterPalette.aura.withValues(alpha: isDark ? 0.12 : 0.14),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 8; i++) {
      final top = size.height * (0.08 + i * 0.12);
      final path = Path()
        ..moveTo(-40, top)
        ..cubicTo(
          size.width * 0.24,
          top - 72,
          size.width * 0.6,
          top + 84,
          size.width + 60,
          top - 26,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPatternPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

