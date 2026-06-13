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
      ),
    );
  }
}
