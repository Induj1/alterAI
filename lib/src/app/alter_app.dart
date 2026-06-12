import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'app_state.dart';
import 'app_theme.dart';

class AlterApp extends ConsumerWidget {
  const AlterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      alterAppControllerProvider.select((state) => state.themeMode),
    );
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ALTER',
      debugShowCheckedModeBanner: false,
      theme: AlterTheme.light(),
      darkTheme: AlterTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

