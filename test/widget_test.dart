// Smoke test: the app boots and renders without throwing.

import 'package:alter/src/app/alter_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://rjudzzcdbhojamfgehhh.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqdWR6emNkYmhvamFtZmdlaGhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExODkyNjgsImV4cCI6MjA5Njc2NTI2OH0.4YH_usTvT0bij4db8qsx9MR5oWUrCp4NBIIvwBjKOMA',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemoryAsyncStorage(),
        detectSessionInUri: false,
      ),
    );
  });

  testWidgets('AlterApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TickerMode(enabled: false, child: AlterApp())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(AlterApp), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }
}
