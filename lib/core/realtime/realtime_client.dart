import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/auth_repository.dart';
import '../config/app_config.dart';
import '../storage/session_storage.dart';

class RealtimeEvent {
  const RealtimeEvent(this.name, this.data);

  final String name;
  final Map<String, dynamic> data;
}

/// Server-pushed events (`message:new`, `conversation:read`, `notification:new`...).
abstract interface class RealtimeClient {
  Stream<RealtimeEvent> get events;

  void dispose();
}

/// `http://10.0.2.2:3000/api` → `http://10.0.2.2:3000/ws` (Socket.IO namespace).
@visibleForTesting
String realtimeUrl(String apiBaseUrl) {
  final uri = Uri.parse(apiBaseUrl);
  return uri.replace(path: '/ws', query: null).toString();
}

/// Socket.IO client authenticated with the current access token. When the server
/// refuses the token (expired, revoked), it refreshes the session through the HTTP
/// client and reconnects.
class SocketIoRealtimeClient implements RealtimeClient {
  SocketIoRealtimeClient({
    required String apiBaseUrl,
    required SessionStorage storage,
    required Future<void> Function() refreshSession,
  }) : _refreshSession = refreshSession {
    _socket = io.io(
      realtimeUrl(apiBaseUrl),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .enableForceNew()
          .setAuthFn((callback) {
            unawaited(
              storage.read().then(
                (session) =>
                    callback({'token': session?.tokens.accessToken ?? ''}),
              ),
            );
          })
          .build(),
    );
    for (final name in _forwarded) {
      _socket.on(name, (data) {
        if (data is Map) {
          _events.add(RealtimeEvent(name, Map<String, dynamic>.from(data)));
        }
      });
    }
    _socket
      ..onConnectError((_) => _recover())
      ..onDisconnect((reason) {
        // The server closed the socket (token expired, logout elsewhere).
        if (reason == 'io server disconnect') {
          _recover(reconnect: true);
        }
      });
  }

  static const _forwarded = [
    'message:new',
    'conversation:read',
    'notification:new',
    'connection:update',
  ];

  late final io.Socket _socket;
  final _events = StreamController<RealtimeEvent>.broadcast();
  final Future<void> Function() _refreshSession;
  DateTime _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  bool _disposed = false;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  Future<void> _recover({bool reconnect = false}) async {
    // At most one refresh every 10 s, whatever the number of failures.
    if (_disposed ||
        DateTime.now().difference(_lastRefresh) < const Duration(seconds: 10)) {
      return;
    }
    _lastRefresh = DateTime.now();
    try {
      await _refreshSession();
    } on Object {
      return;
    }
    if (reconnect && !_disposed) {
      _socket.connect();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _socket.dispose();
    unawaited(_events.close());
  }
}

/// Only exists while signed in; closed on sign-out.
final realtimeClientProvider = Provider<RealtimeClient?>((ref) {
  if (ref.watch(authControllerProvider) is! Authenticated) {
    return null;
  }
  final client = SocketIoRealtimeClient(
    apiBaseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    storage: ref.watch(sessionStorageProvider),
    // Any authenticated call refreshes the token on 401 (dio interceptor).
    refreshSession: () => ref.read(authRepositoryProvider).currentUser(),
  );
  ref.onDispose(client.dispose);
  return client;
});

/// All realtime events of the signed-in user.
final realtimeEventsProvider = StreamProvider<RealtimeEvent>((ref) {
  final client = ref.watch(realtimeClientProvider);
  return client?.events ?? const Stream.empty();
});
