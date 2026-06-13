import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:alter/src/features/auth/application/auth_provider.dart';
import 'package:alter/src/features/backend/application/backend_config_controller.dart';
import 'package:alter/src/features/backend/data/backend_api_client.dart';
import 'package:alter/src/features/device_control/application/phone_control_controller.dart';
import 'package:alter/src/features/life_feed/application/life_feed_provider.dart';
import 'package:alter/src/features/mission/application/mission_control_provider.dart';
import 'package:alter/src/features/reputation/application/reputation_score_provider.dart';
import 'package:alter/src/features/shared/application/alter_data_providers.dart';
import 'package:alter/src/features/voice/application/native_wake_service_controller.dart';
import 'package:alter/src/ui/routes.dart';
import 'package:alter/src/ui/theme.dart';

class SettingsDrawer extends ConsumerStatefulWidget {
  const SettingsDrawer({super.key});
  @override
  ConsumerState<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends ConsumerState<SettingsDrawer> {
  final _gatewayController = TextEditingController();
  bool _gatewayDirty = false;
  bool _backendTesting = false;
  String _backendMessage = '';

  final toggles = <String, bool>{
    'wake': true,
    'calendar': true,
    'resume': true,
    'location': false,
    'notif': true,
    'comm': false,
  };

  @override
  void dispose() {
    _gatewayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.9;
    final wake = ref.watch(nativeWakeServiceControllerProvider);
    final phone = ref.watch(phoneControlControllerProvider);
    final backend = ref.watch(backendConfigProvider);
    backend.whenData((config) {
      if (!_gatewayDirty && _gatewayController.text != config.gatewayUrl) {
        _gatewayController.text = config.gatewayUrl;
      }
    });
    return Drawer(
      width: width,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.0, -1.0),
            radius: 1.3,
            colors: AlterUiTheme.light
                ? const [
                    Color(0xFFECE4F6),
                    Color(0xFFF3EEFB),
                    Color(0xFFECE7F5),
                  ]
                : const [Color(0xFF241A40), Color(0xFF120E1C), AppColors.bg],
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border(left: BorderSide(color: AppColors.white(0.14))),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Settings',
                      style: AppText.display(26, weight: FontWeight.w500),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white(0.06),
                          border: Border.all(color: AppColors.white(0.16)),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  'APPEARANCE',
                  style: AppText.kicker(AppColors.white(0.4), size: 11),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.white(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.white(0.1)),
                  ),
                  child: Row(
                    children: [
                      _themeSeg(
                        'Dark',
                        Icons.dark_mode_outlined,
                        !AlterUiTheme.light,
                        () => setState(() => AlterUiTheme.setLight(false)),
                      ),
                      const SizedBox(width: 8),
                      _themeSeg(
                        'Light',
                        Icons.light_mode_outlined,
                        AlterUiTheme.light,
                        () => setState(() => AlterUiTheme.setLight(true)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'GENERAL',
                  style: AppText.kicker(AppColors.white(0.4), size: 11),
                ),
                const SizedBox(height: 8),
                _menuRow(
                  'Permission hub',
                  'Wake, mic, camera, contacts',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(AlterRoutes.permissions);
                  },
                ),
                _menuRow(
                  'Phone control queue',
                  'Confirm Send/Pay actions',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(AlterRoutes.openclaw);
                  },
                ),
                _menuRow(
                  'Agent console',
                  'Natural language + phone tools',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(AlterRoutes.agent);
                  },
                ),
                _menuRow('Connected platforms', 'Notion, GitHub'),
                _menuRow(
                  'Language & localization',
                  'English, Hindi · 8 supported',
                ),
                _menuRow(
                  'Data management',
                  'Export or delete everything',
                  last: true,
                ),
                const SizedBox(height: 30),
                Text(
                  'BACKEND',
                  style: AppText.kicker(AppColors.white(0.4), size: 11),
                ),
                const SizedBox(height: 10),
                _backendPanel(backend),
                const SizedBox(height: 30),
                Text(
                  'DATA PERMISSIONS',
                  style: AppText.kicker(AppColors.white(0.4), size: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  'You own your data. Alter only reads what you allow.',
                  style: AppText.body(
                    12.5,
                    color: AppColors.white(0.4),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                _toggleRow(
                  'wake',
                  'Voice activation',
                  wake.running
                      ? 'Native Hey Alter service running'
                      : '"Hey Alter" wake word',
                  value: wake.running,
                  onChanged: wake.supported
                      ? (_) => ref
                            .read(nativeWakeServiceControllerProvider.notifier)
                            .toggle()
                      : null,
                ),
                _toggleRow(
                  'accessibility',
                  'Phone control',
                  phone.accessibilityEnabled
                      ? 'Accessibility service enabled'
                      : 'Tap to open accessibility settings',
                  value: phone.accessibilityEnabled,
                  onChanged: (_) async {
                    if (!phone.accessibilityEnabled) {
                      await ref
                          .read(phoneControlControllerProvider.notifier)
                          .openAccessibilitySettings();
                    }
                    await ref
                        .read(phoneControlControllerProvider.notifier)
                        .refresh();
                  },
                ),
                _toggleRow(
                  'calendar',
                  'Calendar access',
                  'Briefs & deadline intelligence',
                  value: toggles['calendar']!,
                  onChanged: (v) => setState(() => toggles['calendar'] = v),
                ),
                _toggleRow(
                  'resume',
                  'Resume sync',
                  'Skills & gap analysis',
                  value: toggles['resume']!,
                  onChanged: (v) => setState(() => toggles['resume'] = v),
                ),
                _toggleRow(
                  'location',
                  'Location data',
                  'Context-aware prompts',
                  value: toggles['location']!,
                  onChanged: (v) => setState(() => toggles['location'] = v),
                ),
                _toggleRow(
                  'notif',
                  'Notification stream',
                  'Extract commitments & deadlines',
                  value: toggles['notif']!,
                  onChanged: (v) => setState(() => toggles['notif'] = v),
                ),
                _toggleRow(
                  'comm',
                  'Communication threads',
                  'Email & messaging context',
                  value: toggles['comm']!,
                  onChanged: (v) => setState(() => toggles['comm'] = v),
                  last: true,
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      context.go(AlterRoutes.login);
                    }
                  },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Sign out',
                      style: AppText.body(
                        14,
                        weight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backendPanel(AsyncValue<BackendConfig> backend) {
    final status = backend.when(
      data: (config) => config.hasGateway
          ? 'Gateway: ${config.gatewayUrl}'
          : 'Gateway not configured',
      loading: () => 'Loading backend settings...',
      error: (error, _) => 'Backend settings unavailable: $error',
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status, style: AppText.body(12.5, color: AppColors.white(0.48))),
          const SizedBox(height: 12),
          TextField(
            controller: _gatewayController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            style: AppText.body(13.5),
            onChanged: (_) => setState(() => _gatewayDirty = true),
            decoration: InputDecoration(
              hintText: 'http://192.168.1.23:8060',
              hintStyle: AppText.body(13.5, color: AppColors.white(0.32)),
              filled: true,
              fillColor: AppColors.white(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.white(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.white(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.lime.withValues(alpha: 0.75),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _backendAction('Save', Icons.save_outlined, _saveBackendUrl),
              const SizedBox(width: 8),
              _backendAction(
                _backendTesting ? 'Testing' : 'Test',
                Icons.network_check,
                _backendTesting ? null : _testBackendUrl,
              ),
              const SizedBox(width: 8),
              _backendAction('Reset', Icons.restart_alt, _resetBackendUrl),
            ],
          ),
          if (_backendMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _backendMessage,
              style: AppText.body(
                12,
                color: AppColors.white(0.5),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _backendAction(
    String label,
    IconData icon,
    Future<void> Function()? action,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: action == null ? null : () => action(),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: action == null ? 0.55 : 1,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.white(0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: AppColors.white(0.72)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      12.5,
                      weight: FontWeight.w700,
                      color: AppColors.white(0.74),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveBackendUrl() async {
    await ref
        .read(backendConfigProvider.notifier)
        .setGatewayUrl(_gatewayController.text);
    _refreshBackendDrivenScreens();
    if (!mounted) return;
    setState(() {
      _gatewayDirty = false;
      _backendMessage = 'Backend gateway saved.';
    });
  }

  Future<void> _testBackendUrl() async {
    final raw = _gatewayController.text.trim();
    if (raw.isEmpty) {
      setState(() => _backendMessage = 'Enter a gateway URL before testing.');
      return;
    }
    setState(() {
      _backendTesting = true;
      _backendMessage = '';
    });
    final url = raw.startsWith(RegExp(r'https?://')) ? raw : 'http://$raw';
    final client = BackendApiClient(baseUrl: url);
    try {
      final health = await client.getJson('/v1/system/health');
      final status = health?['status']?.toString().toUpperCase() ?? 'OK';
      final services = health?['services'] is List
          ? (health!['services'] as List).length
          : 0;
      if (!mounted) return;
      setState(
        () => _backendMessage =
            'Gateway responded $status. Services visible: $services.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _backendMessage =
            'Backend test failed: ${error.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      client.close();
      if (mounted) setState(() => _backendTesting = false);
    }
  }

  Future<void> _resetBackendUrl() async {
    await ref.read(backendConfigProvider.notifier).resetGatewayUrl();
    _refreshBackendDrivenScreens();
    if (!mounted) return;
    setState(() {
      _gatewayDirty = false;
      _backendMessage = 'Backend gateway reset to the platform default.';
    });
  }

  void _refreshBackendDrivenScreens() {
    ref.invalidate(lifeFeedProvider);
    ref.invalidate(missionControlProvider);
    ref.invalidate(cloneCouncilProvider);
    ref.invalidate(futureScenariosProvider);
    ref.invalidate(opportunitySignalsProvider);
    ref.invalidate(reputationEventsProvider);
    ref.invalidate(reputationScoreProvider);
  }

  Widget _themeSeg(
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.pill : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: active ? AppColors.pillInk : AppColors.white(0.6),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppText.body(
                  14,
                  weight: FontWeight.w700,
                  color: active ? AppColors.pillInk : AppColors.white(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuRow(
    String title,
    String sub, {
    bool chevron = true,
    bool last = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 2),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: AppColors.white(0.07))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body(15.5, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: AppText.body(12.5, color: AppColors.white(0.45)),
                  ),
                ],
              ),
            ),
            if (chevron)
              Icon(Icons.chevron_right, color: AppColors.white(0.35)),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(
    String key,
    String title,
    String sub, {
    bool last = false,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: AppColors.white(0.07))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body(15.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppText.body(12.5, color: AppColors.white(0.45)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onChanged == null ? null : () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 27,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? AppColors.lime : AppColors.white(0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? AppColors.bg : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
