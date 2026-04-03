import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_check/utils/router.dart';
import 'package:run_check/utils/theme.dart';

class RunCheckApp extends ConsumerWidget {
  const RunCheckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Run Check',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
