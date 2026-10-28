import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/offline/connectivity.dart';
import 'core/router/app_router.dart';
import 'core/theme/risotto_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/dashboard/application/dashboard_provider.dart';
import 'features/messaging/application/messaging_providers.dart';
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
      builder: (context, child) => Column(
        children: [
          if (ref.watch(offlineProvider)) const _OfflineBanner(),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

/// Shown on top of every screen while the API is unreachable.
class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.inverseSurface,
      child: SafeArea(
        bottom: false,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: colors.onInverseSurface, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hors ligne : dernières données connues, envoi impossible.',
                    style: TextStyle(color: colors.onInverseSurface),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onInverseSurface,
                  ),
                  // Any successful request clears the banner.
                  onPressed: () => ref
                    ..invalidate(dashboardProvider)
                    ..invalidate(conversationsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
