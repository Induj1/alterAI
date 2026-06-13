import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Plain ChangeNotifier used as GoRouter's refreshListenable.
// Instantiated inside appRouterProvider (not a Riverpod provider itself).
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _sub;

  void refresh() => notifyListeners();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// Riverpod stream of auth state changes (for screens that need to react).
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Current user — re-evaluates whenever auth state stream emits.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateStreamProvider);
  return Supabase.instance.client.auth.currentUser;
});

class AuthService {
  AuthService(this._client);
  final SupabaseClient _client;

  Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(String email, String password) =>
      _client.auth.signUp(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});
