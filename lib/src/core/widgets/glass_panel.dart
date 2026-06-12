import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/alter_palette.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 8,
    this.onTap,
    this.borderOpacity = 0.34,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? Colors.white.withValues(alpha: 0.065)
        : Colors.white.withValues(alpha: 0.64);
    final border = isDark
        ? Colors.white.withValues(alpha: borderOpacity * 0.42)
        : Colors.white.withValues(alpha: borderOpacity);

    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: AlterPalette.iris.withValues(alpha: isDark ? 0.18 : 0.09),
                blurRadius: 36,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) {
      return panel;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: panel,
      ),
    );
  }
}

class GradientBorderPanel extends StatelessWidget {
  const GradientBorderPanel({
    required this.child,
    this.padding = const EdgeInsets.all(1),
    this.radius = 8,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AlterPalette.premiumGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: padding,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: child,
        ),
      ),
    );
  }
}

