import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/digital_twin_models.dart';

final digitalTwinProvider =
    AsyncNotifierProvider<DigitalTwinController, DigitalTwinState>(
      DigitalTwinController.new,
    );

class DigitalTwinController extends AsyncNotifier<DigitalTwinState> {
  @override
  Future<DigitalTwinState> build() => _load();

  Future<void> setAccess(
    DigitalTwinSource source,
    TwinAccessLevel accessLevel,
  ) async {
    final next = (state.asData?.value ?? DigitalTwinState.defaults())
        .withSource(source, accessLevel);
    state = AsyncValue.data(next);
    await _persistSource(next.consentFor(source));
  }

  Future<void> setAutonomy(TwinAutonomyLevel autonomyLevel) async {
    final next = (state.asData?.value ?? DigitalTwinState.defaults()).copyWith(
      autonomyLevel: autonomyLevel,
      updatedAt: DateTime.now(),
    );
    state = AsyncValue.data(next);
    await _persistSettings(next);
  }

  Future<void> stageCompleteTwin() async {
    final next = (state.asData?.value ?? DigitalTwinState.defaults())
        .stageCompleteTwin();
    state = AsyncValue.data(next);
    await Future.wait([
      for (final consent in next.sources.values) _persistSource(consent),
      _persistSettings(next),
    ]);
  }

  Future<DigitalTwinState> _load() async {
    var loaded = DigitalTwinState.defaults();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return loaded;

    try {
      final rows = await Supabase.instance.client
          .from('digital_twin_sources')
          .select('source_key, access_level, connected')
          .eq('user_id', userId);
      final next = Map<DigitalTwinSource, TwinSourceConsent>.from(
        loaded.sources,
      );
      for (final row in rows) {
        final consent = TwinSourceConsent.fromJson(row);
        next[consent.source] = consent;
      }
      loaded = loaded.copyWith(sources: next);
    } catch (_) {}

    try {
      final settings = await Supabase.instance.client
          .from('digital_twin_settings')
          .select('autonomy_level, updated_at')
          .eq('user_id', userId)
          .maybeSingle();
      if (settings != null) {
        loaded = loaded.copyWith(
          autonomyLevel: TwinAutonomyLevel.fromId(
            (settings['autonomy_level'] ?? '').toString(),
          ),
          updatedAt:
              DateTime.tryParse((settings['updated_at'] ?? '').toString()) ??
              loaded.updatedAt,
        );
      }
    } catch (_) {}

    return loaded;
  }

  Future<void> _persistSource(TwinSourceConsent consent) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('digital_twin_sources').upsert({
        'user_id': userId,
        'source_key': consent.source.id,
        'access_level': consent.accessLevel.id,
        'connected': consent.connected,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _persistSettings(DigitalTwinState next) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('digital_twin_settings').upsert({
        'user_id': userId,
        'autonomy_level': next.autonomyLevel.id,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}
