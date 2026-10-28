import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/realtime_client.dart';
import '../../auth/application/auth_controller.dart';
import '../../connections/application/connections_providers.dart';
import '../data/notifications_models.dart';
import '../data/notifications_repository.dart';

class NotificationsState {
  const NotificationsState({
    required this.notifications,
    required this.unreadCount,
    this.nextCursor,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final String? nextCursor;
}

/// The notification list, kept live by `notification:new` socket events.
class NotificationsController extends AsyncNotifier<NotificationsState> {
  NotificationsRepository get _repository =>
      ref.read(notificationsRepositoryProvider);

  @override
  Future<NotificationsState> build() async {
    if (ref.watch(authControllerProvider) is! Authenticated) {
      return const NotificationsState(notifications: [], unreadCount: 0);
    }
    ref.listen(realtimeEventsProvider, (_, next) {
      final event = next.value;
      if (event?.name == 'notification:new') {
        _onNew(AppNotification.fromJson(event!.data));
      }
    });
    return _load();
  }

  Future<NotificationsState> _load() async {
    final page = await _repository.list();
    return NotificationsState(
      notifications: page.notifications,
      unreadCount: page.unreadCount,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> refresh() async {
    state = AsyncData(await _load());
  }

  void _onNew(AppNotification notification) {
    final current = state.value;
    if (current != null &&
        !current.notifications.any((n) => n.id == notification.id)) {
      state = AsyncData(
        NotificationsState(
          notifications: [notification, ...current.notifications],
          unreadCount: current.unreadCount + 1,
          nextCursor: current.nextCursor,
        ),
      );
    }
    // Connection notifications change the network lists too.
    ref
      ..invalidate(connectionRequestsProvider)
      ..invalidate(myConnectionsProvider);
  }

  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final target = current.notifications.where((n) => n.id == id).firstOrNull;
    if (target == null || target.isRead) {
      return;
    }
    await _repository.markRead(id);
    state = AsyncData(
      NotificationsState(
        notifications: [
          for (final n in current.notifications)
            n.id == id ? n.markedRead() : n,
        ],
        unreadCount: (current.unreadCount - 1).clamp(0, 1 << 30),
        nextCursor: current.nextCursor,
      ),
    );
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    await _repository.markAllRead();
    state = AsyncData(
      NotificationsState(
        notifications: [for (final n in current.notifications) n.markedRead()],
        unreadCount: 0,
        nextCursor: current.nextCursor,
      ),
    );
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

final unreadNotificationsCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).value?.unreadCount ?? 0,
);

/// Latest notification pushed in real time, for the in-app banner.
final incomingNotificationProvider = StreamProvider<AppNotification>((ref) {
  return ref
          .watch(realtimeClientProvider)
          ?.events
          .where((event) => event.name == 'notification:new')
          .map((event) => AppNotification.fromJson(event.data)) ??
      const Stream.empty();
});

class NotificationPreferencesController
    extends AsyncNotifier<List<NotificationPreference>> {
  @override
  Future<List<NotificationPreference>> build() =>
      ref.read(notificationsRepositoryProvider).preferences();

  /// Optimistic: the switch moves at once and reverts if the server refuses.
  Future<void> change(NotificationPreference updated) async {
    final previous = state.value ?? const [];
    state = AsyncData([
      for (final p in previous) p.kind == updated.kind ? updated : p,
    ]);
    try {
      state = AsyncData(
        await ref.read(notificationsRepositoryProvider).updatePreferences([
          updated,
        ]),
      );
    } on Object {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationPreferencesController,
      List<NotificationPreference>
    >(NotificationPreferencesController.new);
