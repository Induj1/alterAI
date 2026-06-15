import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../../../data/local/contextos_dao.dart';
import '../../../data/local/dao_providers.dart';
import '../domain/contextos_models.dart';

class ContextOsPrefs {
  const ContextOsPrefs({
    this.privateModeDefault = false,
    this.cloudConsent = true,
    this.enabledSurfaces = const {
      'notification',
      'share_sheet',
      'camera',
      'mic',
      'qr',
      'install',
      'manual',
    },
  });

  final bool privateModeDefault;
  final bool cloudConsent;
  final Set<String> enabledSurfaces;

  bool isSurfaceEnabled(MomentSource s) => enabledSurfaces.contains(s.id);

  ContextOsPrefs copyWith({
    bool? privateModeDefault,
    bool? cloudConsent,
    Set<String>? enabledSurfaces,
  }) =>
      ContextOsPrefs(
        privateModeDefault: privateModeDefault ?? this.privateModeDefault,
        cloudConsent: cloudConsent ?? this.cloudConsent,
        enabledSurfaces: enabledSurfaces ?? this.enabledSurfaces,
      );
}

final preferencesProvider =
    AsyncNotifierProvider<PreferencesController, ContextOsPrefs>(
  PreferencesController.new,
);

class PreferencesController extends AsyncNotifier<ContextOsPrefs> {
  @override
  Future<ContextOsPrefs> build() => _load();

  Future<ContextOsPrefs> _load() async {
    ref.watch(isDbUnlockedProvider);
    final userId = ref.read(localUserIdProvider);
    if (userId == null) return const ContextOsPrefs();
    try {
      final row =
          await ref.read(contextOsDaoProvider).getContextOsPreferences(userId);
      return row?.toPrefs() ?? const ContextOsPrefs();
    } catch (_) {
      return const ContextOsPrefs();
    }
  }

  Future<void> _save(ContextOsPrefs p) async {
    state = AsyncValue.data(p);
    final userId = ref.read(localUserIdProvider);
    if (userId == null) return;
    try {
      await ref.read(contextOsDaoProvider).upsertContextOsPreferences(
            ContextOsPreferencesRecord(
              userId: userId,
              privateModeDefault: p.privateModeDefault,
              cloudConsent: p.cloudConsent,
              enabledSurfaces: p.enabledSurfaces.toList(),
              updatedAt: DateTime.now(),
            ),
          );
    } catch (_) {}
  }

  Future<void> setPrivateDefault(bool v) async {
    final p = (state.asData?.value ?? const ContextOsPrefs())
        .copyWith(privateModeDefault: v);
    await _save(p);
  }

  Future<void> setCloudConsent(bool v) async {
    final p = (state.asData?.value ?? const ContextOsPrefs())
        .copyWith(cloudConsent: v);
    await _save(p);
  }

  Future<void> toggleSurface(MomentSource s) async {
    final cur = state.asData?.value ?? const ContextOsPrefs();
    final next = {...cur.enabledSurfaces};
    if (next.contains(s.id)) {
      next.remove(s.id);
    } else {
      next.add(s.id);
    }
    await _save(cur.copyWith(enabledSurfaces: next));
  }
}
