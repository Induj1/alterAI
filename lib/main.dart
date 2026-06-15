import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alter/src/core/config/alter_gateway_config.dart';

import 'src/app/alter_app.dart';
import 'src/ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await FlutterGemma.initialize();
    } catch (_) {}
  }

  final prefs = await SharedPreferences.getInstance();
  AlterUiTheme.isLight.value = prefs.getBool('alter_theme_light') ?? false;
  await AlterGatewayConfig.loadFromPrefs();

  runApp(const ProviderScope(child: AlterApp()));
}
