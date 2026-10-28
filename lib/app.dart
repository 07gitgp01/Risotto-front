import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/risotto_theme.dart';

class RisottoApp extends ConsumerWidget {
  const RisottoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Risotto',
      debugShowCheckedModeBanner: false,
      theme: buildRisottoTheme(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
