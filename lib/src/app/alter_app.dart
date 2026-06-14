import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/theme.dart';
import 'app_router.dart';

class AlterApp extends ConsumerWidget {
  const AlterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return ValueListenableBuilder<bool>(
      valueListenable: AlterUiTheme.isLight,
      builder: (_, light, __) => MaterialApp.router(
        title: 'Alter',
        debugShowCheckedModeBanner: false,
        theme: buildAlterTheme(light),
        routerConfig: router,
        // Give every route a Material ancestor so raw Text widgets inherit the
        // theme's default text style. Without this, screens built on a bare
        // DecoratedBox (e.g. the agent screen) render Flutter's fallback style,
        // which paints a yellow underline under every line of text.
        builder: (context, child) => Material(
          type: MaterialType.transparency,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
