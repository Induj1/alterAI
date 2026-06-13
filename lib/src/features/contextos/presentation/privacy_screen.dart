import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alter_palette.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../application/memory_engine.dart';
import '../application/preferences_controller.dart';
import '../domain/contextos_models.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  static const _surfaces = [
    MomentSource.notification,
    MomentSource.shareSheet,
    MomentSource.camera,
    MomentSource.mic,
    MomentSource.screenshot,
    MomentSource.sms,
    MomentSource.whatsapp,
    MomentSource.social,
    MomentSource.notes,
    MomentSource.photos,
    MomentSource.contacts,
    MomentSource.calendar,
    MomentSource.email,
    MomentSource.browser,
    MomentSource.location,
    MomentSource.files,
    MomentSource.qr,
    MomentSource.call,
    MomentSource.payment,
    MomentSource.install,
    MomentSource.manual,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefsAsync = ref.watch(preferencesProvider);
    final prefs = prefsAsync.asData?.value ?? const ContextOsPrefs();
    final notifier = ref.read(preferencesProvider.notifier);

    return AmbientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'Privacy & Permissions',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You control what ALTER senses and what leaves the phone. '
            'Sensitive data is redacted on-device before any cloud call.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              children: [
                _SwitchRow(
                  icon: LucideIcons.lock,
                  title: 'Private Mode by default',
                  subtitle: 'New moments stay on-device — no cloud reasoning.',
                  value: prefs.privateModeDefault,
                  onChanged: notifier.setPrivateDefault,
                ),
                const Divider(height: 22),
                _SwitchRow(
                  icon: LucideIcons.cloud,
                  title: 'Allow cloud reasoning',
                  subtitle:
                      'Escalate redacted moments for deeper proof — only with consent.',
                  value: prefs.cloudConsent,
                  onChanged: notifier.setCloudConsent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.toggle_right,
                      size: 18,
                      color: AlterPalette.iris,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Per-source sensing',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Disable any surface you don’t want ALTER to read.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
                const SizedBox(height: 6),
                for (final s in _surfaces)
                  _SwitchRow(
                    icon: s.icon,
                    title: s.label,
                    subtitle: '',
                    value: prefs.isSurfaceEnabled(s),
                    onChanged: (_) => notifier.toggleSurface(s),
                    dense: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassPanel(
            onTap: () => context.go('/mission'),
            child: Row(
              children: [
                Icon(
                  LucideIcons.scroll_text,
                  size: 18,
                  color: AlterPalette.cyan,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Action audit log',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Every edge/cloud/consent/action event — in Mission Control.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.58,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevron_right, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete memory',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Forget every trusted source. ALTER will re-evaluate all sources from scratch.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.trash_2, size: 16),
                  label: const Text('Delete all memories'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AlterPalette.danger,
                  ),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all memories?'),
        content: const Text(
          'This removes every trusted source. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AlterPalette.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(memoryProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All memories deleted.')));
      }
    }
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 2 : 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AlterPalette.iris),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.56,
                      ),
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
