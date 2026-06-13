import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/openai_service.dart';
import '../domain/user_profile.dart';

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
      UserProfileNotifier.new,
    );

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await Supabase.instance.client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> save(UserProfile profile) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    state = const AsyncValue.loading();

    try {
      await Supabase.instance.client.from('user_profiles').upsert({
        'id': userId,
        ...profile.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void setLocal(UserProfile profile) {
    state = AsyncValue.data(profile);
  }
}

/// AI is available to any authenticated user: requests are proxied through the
/// `openai-chat` Edge Function, which holds the platform OpenAI key server-side.
///
/// Returns `null` only when there is no signed-in session. If the user has set
/// their own key (BYOK), it is forwarded so the function bills against it and
/// skips the platform quota.
final openAIServiceProvider = Provider<OpenAIService?>((ref) {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return null;

  final profile = ref.watch(userProfileProvider).asData?.value;
  final byok = profile?.openaiKey.isNotEmpty == true
      ? profile!.openaiKey
      : null;

  final service = OpenAIService(byokKey: byok);
  ref.onDispose(service.dispose);
  return service;
});
