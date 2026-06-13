import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrustedEntity {
  const TrustedEntity({this.id, required this.type, required this.value});

  final String? id;
  final String type; // domain | contact | app
  final String value;
}

/// MemoryEngine (trust slice) — remembers contacts/domains/apps the user has
/// vouched for so LifeShield stops re-warning about them. Backed by
/// `trusted_entities`; best-effort + in-memory so it works pre-migration.
final memoryProvider =
    AsyncNotifierProvider<MemoryEngine, List<TrustedEntity>>(MemoryEngine.new);

class MemoryEngine extends AsyncNotifier<List<TrustedEntity>> {
  @override
  Future<List<TrustedEntity>> build() => _load();

  Future<List<TrustedEntity>> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final rows = (await Supabase.instance.client
              .from('trusted_entities')
              .select('id, entity_type, value')
              .eq('user_id', userId)
              .order('created_at', ascending: false) as List)
          .cast<Map<String, dynamic>>();
      return rows
          .map((r) => TrustedEntity(
                id: r['id']?.toString(),
                type: (r['entity_type'] ?? 'domain').toString(),
                value: (r['value'] ?? '').toString(),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addTrusted(String type, String value) async {
    final v = value.trim();
    if (v.isEmpty) return;
    final current = state.asData?.value ?? const [];
    if (current.any((e) => e.value.toLowerCase() == v.toLowerCase())) return;

    // Optimistic in-memory add so the UI updates even pre-migration.
    state = AsyncValue.data([TrustedEntity(type: type, value: v), ...current]);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('trusted_entities').insert({
        'user_id': userId,
        'entity_type': type,
        'value': v,
      });
      state = AsyncValue.data(await _load());
    } catch (_) {}
  }

  Future<void> remove(TrustedEntity entity) async {
    final current = state.asData?.value ?? const [];
    state = AsyncValue.data(
        current.where((e) => e.value != entity.value).toList());
    if (entity.id == null) return;
    try {
      await Supabase.instance.client
          .from('trusted_entities')
          .delete()
          .eq('id', entity.id!);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    final current = state.asData?.value ?? const [];
    state = const AsyncValue.data([]);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || current.isEmpty) return;
    try {
      await Supabase.instance.client
          .from('trusted_entities')
          .delete()
          .eq('user_id', userId);
    } catch (_) {}
  }

  /// Returns the trusted value that appears in [text], if any.
  static String? matchIn(List<TrustedEntity> trusted, String text) {
    final lower = text.toLowerCase();
    for (final e in trusted) {
      if (e.value.isNotEmpty && lower.contains(e.value.toLowerCase())) {
        return e.value;
      }
    }
    return null;
  }
}
