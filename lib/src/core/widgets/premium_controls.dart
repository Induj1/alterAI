import 'package:flutter/material.dart';

import '../theme/alter_palette.dart';

class PremiumButton extends StatelessWidget {
  const PremiumButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AlterPalette.premiumGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AlterPalette.iris.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: Size(compact ? 0 : 160, compact ? 44 : 54),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 20,
            vertical: compact ? 10 : 14,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class PremiumChip extends StatelessWidget {
  const PremiumChip({
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AlterPalette.iris : theme.colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AlterPalette.iris.withValues(alpha: 0.16)
                : theme.colorScheme.surface.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AlterPalette.iris.withValues(alpha: 0.34)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 14), trailing!],
      ],
    );
  }
}
