import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alter_palette.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/premium_controls.dart';
import '../application/permission_hub_controller.dart';

class PermissionHubScreen extends ConsumerStatefulWidget {
  const PermissionHubScreen({super.key});

  @override
  ConsumerState<PermissionHubScreen> createState() =>
      _PermissionHubScreenState();
}

class _PermissionHubScreenState extends ConsumerState<PermissionHubScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionHubControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionHubControllerProvider);
    final controller = ref.read(permissionHubControllerProvider.notifier);
    final theme = Theme.of(context);
    final progress = state.items.isEmpty
        ? 0.0
        : state.grantedCount / state.items.length;

    return Scaffold(
      body: AmbientScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientText(
              'Permission Hub',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable ALTER like an assistant: wake word, phone control, notification context, camera, and contacts.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: state.essentialsReady
                        ? 'Essentials ready'
                        : 'Enable essentials',
                    subtitle:
                        '${state.grantedEssentialCount}/${state.essentialCount} essential permissions enabled.',
                    trailing: PremiumButton(
                      label: 'Refresh',
                      compact: true,
                      icon: LucideIcons.refresh_ccw,
                      onPressed: state.loading ? null : controller.refresh,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: progress.clamp(0, 1),
                    ),
                  ),
                  if (state.error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      state.error,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AlterPalette.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: PremiumButton(
                          label: 'Ask runtime permissions',
                          icon: LucideIcons.shield_check,
                          onPressed: state.loading
                              ? null
                              : controller.requestRuntimePermissions,
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        icon: const Icon(LucideIcons.settings, size: 16),
                        label: const Text('App settings'),
                        onPressed: state.loading
                            ? null
                            : controller.openAppSettings,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final item in state.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PermissionRow(
                  item: item,
                  loading: state.loading,
                  onTap: () => controller.request(item.id),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    label: 'Continue to ALTER',
                    icon: LucideIcons.arrow_right,
                    onPressed: () => context.go('/agent'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => context.go('/agent'),
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.item,
    required this.loading,
    required this.onTap,
  });

  final PermissionHubItem item;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final granted = item.granted;
    final accent = granted ? AlterPalette.mint : AlterPalette.iris;
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(item.icon, color: accent, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (item.essential)
                      PremiumChip(
                        label: 'Essential',
                        selected: !granted,
                        icon: LucideIcons.shield_check,
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            icon: Icon(
              granted ? LucideIcons.circle_check : LucideIcons.arrow_right,
              size: 16,
            ),
            label: Text(
              granted
                  ? 'On'
                  : item.opensSettings
                  ? 'Settings'
                  : 'Allow',
            ),
            onPressed: loading || granted ? null : onTap,
          ),
        ],
      ),
    );
  }
}
