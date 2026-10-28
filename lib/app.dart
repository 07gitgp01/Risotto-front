import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/risotto_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/notifications/application/notifications_providers.dart';
import 'features/notifications/application/push_registration.dart';
import 'features/notifications/presentation/notification_routes.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class RisottoApp extends ConsumerStatefulWidget {
  const RisottoApp({super.key});

  @override
  ConsumerState<RisottoApp> createState() => _RisottoAppState();
}

class _RisottoAppState extends ConsumerState<RisottoApp> {
  StreamSubscription<Map<String, String>>? _openedPushes;

  @override
  void initState() {
    super.initState();
    // Registers the device for push on every sign-in (sign-out is handled by
    // AuthController, before the session is revoked).
    ref.listenManual(authControllerProvider, (previous, next) {
      if (next is Authenticated && previous is! Authenticated) {
        unawaited(ref.read(pushRegistrationProvider).onSignedIn());
      }
    }, fireImmediately: true);
    // Tapping a push notification opens the matching screen.
    _openedPushes = ref.read(pushServiceProvider).openedNotifications.listen((
      data,
    ) {
      final route = routeForPushData(data);
      if (route != null) {
        unawaited(ref.read(appRouterProvider).push(route));
      }
    });
  }

  @override
  void dispose() {
    unawaited(_openedPushes?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // In-app banner for notifications received in real time.
    ref.listen(incomingNotificationProvider, (_, next) {
      final notification = next.value;
      if (notification == null) {
        return;
      }
      final route = routeForNotification(notification.kind, notification.data);
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(notification.text),
          action: route == null
              ? null
              : SnackBarAction(
                  label: 'Voir',
                  onPressed: () =>
                      unawaited(ref.read(appRouterProvider).push(route)),
                ),
        ),
      );
    });

    return MaterialApp.router(
      title: 'Risotto',
      debugShowCheckedModeBanner: false,
      theme: buildRisottoTheme(),
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
