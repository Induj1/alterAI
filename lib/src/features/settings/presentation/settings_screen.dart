import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_state.dart';
import '../../../core/theme/alter_palette.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/premium_controls.dart';
import '../../auth/application/auth_provider.dart';
import '../../profile/application/profile_provider.dart';
import '../../profile/domain/user_profile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _keyObscured = true;
  bool _keySaved = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing key when profile loads
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile?.openaiKey.isNotEmpty == true) {
      _keyController.text = profile!.openaiKey;
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(alterAppControllerProvider);
    final controller = ref.read(alterAppControllerProvider.notifier);
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final profile = ref.watch(userProfileProvider).asData?.value;
    final hasKey = profile?.openaiKey.isNotEmpty == true;

    // Sync key controller when profile loads
    ref.listen(userProfileProvider, (_, next) {
      final p = next.asData?.value;
      if (p != null && _keyController.text.isEmpty && p.openaiKey.isNotEmpty) {
        _keyController.text = p.openaiKey;
      }
    });

    return AmbientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'Settings',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tune theme, privacy, model stack, voice preferences, and connected systems.',
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
              MetricTile(
                label: 'Model routing',
                value: hasKey ? 'Your key' : 'Shared',
                icon: LucideIcons.brain_circuit,
                accent: AlterPalette.mint,
              ),
              const MetricTile(
                label: 'Memory vault',
                value: 'Locked',
                icon: LucideIcons.lock,
                accent: AlterPalette.iris,
              ),
              const MetricTile(
                label: 'Latency target',
                value: '<300 ms',
                icon: LucideIcons.zap,
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
                  title: 'Appearance',
                  subtitle: 'Use system theme or force a precise mode.',
                ),
                const SizedBox(height: 16),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 8),
                    ),
                    textStyle: WidgetStatePropertyAll(
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Auto'),
                      icon: Icon(LucideIcons.monitor),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(LucideIcons.sun),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(LucideIcons.moon),
                    ),
                  ],
                  selected: {appState.themeMode},
                  onSelectionChanged: (s) => controller.setThemeMode(s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'AI Configuration',
                  subtitle: hasKey
                      ? 'Using your own OpenAI key — unlimited, billed to your account.'
                      : 'Running on the ALTER shared key (fair-use daily limit). Add your own key below for unlimited use.',
                  trailing: PremiumChip(
                    label: hasKey ? 'Your key' : 'Shared key',
                    selected: true,
                    icon: LucideIcons.circle_check,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _keyController,
                  obscureText: _keyObscured,
                  decoration: InputDecoration(
                    labelText: 'OpenAI API Key',
                    hintText: 'sk-...',
                    prefixIcon: const Icon(LucideIcons.key_round),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _keyObscured
                                ? LucideIcons.eye
                                : LucideIcons.eye_off,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _keyObscured = !_keyObscured),
                        ),
                        if (_keyController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () {
                              _keyController.clear();
                              setState(() => _keySaved = false);
                            },
                          ),
                      ],
                    ),
                    helperText: _keySaved
                        ? 'Key saved — your requests now use your own key'
                        : 'Optional. Get a key at platform.openai.com for unlimited use',
                    helperStyle: TextStyle(
                      color: _keySaved ? AlterPalette.mint : null,
                    ),
                  ),
                  onChanged: (_) => setState(() => _keySaved = false),
                ),
                const SizedBox(height: 14),
                PremiumButton(
                  label: 'Save API Key',
                  icon: LucideIcons.save,
                  compact: true,
                  onPressed: _saveApiKey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: SectionHeader(
              title: 'Permissions',
              subtitle:
                  'Review microphone, notifications, Accessibility, camera, contacts, and notification access.',
              trailing: PremiumButton(
                label: 'Open hub',
                compact: true,
                icon: LucideIcons.shield_check,
                onPressed: () => context.go('/permissions'),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ResponsiveGrid(
            mediumColumns: 2,
            expandedColumns: 2,
            children: [
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Privacy',
                      subtitle:
                          'Agent actions stay permissioned and auditable.',
                    ),
                    const SizedBox(height: 14),
                    _SwitchRow(
                      icon: LucideIcons.shield_check,
                      title: 'Privacy shield',
                      subtitle: 'Require confirmation before external actions.',
                      value: appState.privacyShield,
                      onChanged: controller.setPrivacyShield,
                    ),
                    _SwitchRow(
                      icon: LucideIcons.bell,
                      title: 'Proactive briefs',
                      subtitle: 'Let ALTER prepare daily next-move briefings.',
                      value: appState.proactiveBriefs,
                      onChanged: controller.setProactiveBriefs,
                    ),
                  ],
                ),
              ),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Connected systems',
                      subtitle: 'Production adapters wired to live services.',
                    ),
                    const SizedBox(height: 14),
                    const _SystemRow(
                      'Supabase',
                      'Auth, Postgres, Edge Functions',
                    ),
                    _SystemRow(
                      'OpenAI',
                      hasKey ? 'Your key (BYOK)' : 'Shared key via proxy',
                    ),
                    const _SystemRow('Neo4j', 'Social graph backend adapter'),
                    const _SystemRow(
                      'Qdrant',
                      'Vector memory service in backend stack',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Account',
                  subtitle: 'Manage your ALTER identity.',
                ),
                const SizedBox(height: 14),
                if (profile != null && profile.displayName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AlterPalette.iris.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              LucideIcons.user,
                              color: AlterPalette.iris,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                profile.role.isNotEmpty
                                    ? profile.role
                                    : user?.email ?? '—',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.58,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(LucideIcons.pencil, size: 16),
                          label: const Text('Edit'),
                          onPressed: () => context.go('/profile'),
                        ),
                      ],
                    ),
                  )
                else if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AlterPalette.iris.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              LucideIcons.user,
                              color: AlterPalette.iris,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Signed in',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                user.email ?? '—',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.58,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(LucideIcons.user_cog, size: 16),
                          label: const Text('Set up profile'),
                          onPressed: () => context.go('/profile'),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.log_out, size: 18),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AlterPalette.danger,
                      side: BorderSide(
                        color: AlterPalette.danger.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveApiKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    final notifier = ref.read(userProfileProvider.notifier);
    final existing = ref.read(userProfileProvider).asData?.value;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final toSave = existing != null
        ? existing.copyWith(openaiKey: key)
        : UserProfile(
            id: userId,
            displayName: '',
            role: '',
            careerStage: '',
            industry: '',
            bio: '',
            skills: const [],
            goals: const [],
            interests: const [],
            openaiKey: key,
            onboardingDone: false,
          );

    await notifier.save(toSave);
    if (mounted) setState(() => _keySaved = true);
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AlterPalette.iris.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: AlterPalette.iris, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
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

class _SystemRow extends StatelessWidget {
  const _SystemRow(this.name, this.detail);

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(LucideIcons.check, color: AlterPalette.mint, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
