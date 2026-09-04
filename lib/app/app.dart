import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class GoBarokahApp extends ConsumerWidget {
  const GoBarokahApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Go-Barokah Cashier',
      theme: appTheme,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
