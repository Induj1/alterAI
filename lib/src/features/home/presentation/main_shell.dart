import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alter_palette.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    required this.child,
    required this.location,
    super.key,
  });

  final Widget child;
  final String location;

  static const items = [
    _NavItem('/mission', 'Control', LucideIcons.command),
    _NavItem('/voice', 'Voice', LucideIcons.mic),
    _NavItem('/council', 'Council', LucideIcons.messages_square),
    _NavItem('/simulator', 'Future', LucideIcons.route),
    _NavItem('/radar', 'Radar', LucideIcons.radar),
    _NavItem('/social', 'Graph', LucideIcons.network),
    _NavItem('/nfc', 'NFC', LucideIcons.nfc),
    _NavItem('/reputation', 'Rep', LucideIcons.trophy),
    _NavItem('/lens', 'Lens', LucideIcons.scan_eye),
    _NavItem('/settings', 'Settings', LucideIcons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: context.isExpanded
          ? Row(
              children: [
                _DesktopRail(location: location),
                Expanded(child: child),
              ],
            )
          : Stack(
              children: [
                Positioned.fill(child: child),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12 + MediaQuery.paddingOf(context).bottom,
                  child: _MobileNav(location: location),
                ),
              ],
            ),
    );
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 108,
      padding: EdgeInsets.fromLTRB(
        14,
        18 + MediaQuery.paddingOf(context).top,
        14,
        18,
      ),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Column(
          children: [
            GradientText(
              'A',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 22),
            for (final item in MainShell.items)
              _RailButton(
                item: item,
                selected: location == item.path,
              ),
            const Spacer(),
            Icon(
              LucideIcons.shield_check,
              color: AlterPalette.mint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: item.label,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(item.path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? AlterPalette.iris.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? AlterPalette.iris.withValues(alpha: 0.26)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              item.icon,
              color: selected
                  ? AlterPalette.iris
                  : theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      radius: 8,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final item in MainShell.items)
              _MobileNavButton(
                item: item,
                selected: location == item.path,
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavButton extends StatelessWidget {
  const _MobileNavButton({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(item.path),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: const BoxConstraints(minWidth: 58),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AlterPalette.iris.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: selected
                    ? AlterPalette.iris
                    : theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? AlterPalette.iris
                      : theme.colorScheme.onSurface.withValues(alpha: 0.62),
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

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}
