import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/alter_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On-device Gemma runtime (phone only; heuristic fallback elsewhere).
  if (!kIsWeb) {
    try {
      FlutterGemma.initialize();
    } catch (_) {
      // If the runtime can't init, the edge engine stays on heuristics.
    }
  }

  await Supabase.initialize(
    url: 'https://rjudzzcdbhojamfgehhh.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqdWR6emNkYmhvamFtZmdlaGhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExODkyNjgsImV4cCI6MjA5Njc2NTI2OH0.4YH_usTvT0bij4db8qsx9MR5oWUrCp4NBIIvwBjKOMA',
  );
  runApp(const ProviderScope(child: AlterApp()));
}
