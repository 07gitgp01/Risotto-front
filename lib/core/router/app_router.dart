import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/welcome_screen.dart';

abstract final class AppRoutes {
  static const welcome = '/';
}

/// Auth-based redirects are added in milestone 2.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
