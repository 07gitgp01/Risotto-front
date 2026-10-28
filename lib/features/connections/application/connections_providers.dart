import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../contacts/application/contacts_providers.dart';
import '../../profile/application/my_profile_controller.dart';
import '../../profile/data/profile_models.dart';
import '../data/connections_models.dart';
import '../data/connections_repository.dart';

/// Lists are tied to the signed-in account: they reload on sign-in / sign-out.
List<T> _signedOut<T>() => <T>[];

final myConnectionsProvider = FutureProvider<List<Connection>>((ref) {
  if (ref.watch(authControllerProvider) is! Authenticated) {
    return _signedOut();
  }
  return ref.watch(connectionsRepositoryProvider).connections();
});

final connectionRequestsProvider =
    FutureProvider.family<List<Connection>, RequestDirection>((ref, direction) {
      if (ref.watch(authControllerProvider) is! Authenticated) {
        return _signedOut();
      }
      return ref.watch(connectionsRepositoryProvider).requests(direction);
    });

final blockedUsersProvider = FutureProvider.autoDispose<List<BlockedUser>>(
  (ref) => ref.watch(connectionsRepositoryProvider).blocked(),
);

final memberSearchProvider = FutureProvider.autoDispose
    .family<List<Profile>, String>((ref, query) {
      final trimmed = query.trim();
      if (trimmed.length < 2) {
        return const [];
      }
      return ref.watch(connectionsRepositoryProvider).search(trimmed);
    });

/// Connection actions; each one refreshes every list that may have changed.
class ConnectionActions {
  ConnectionActions(this._ref);

  final Ref _ref;

  ConnectionsRepository get _repository =>
      _ref.read(connectionsRepositoryProvider);

  void _refresh([String? userId]) {
    _ref
      ..invalidate(myConnectionsProvider)
      ..invalidate(connectionRequestsProvider)
      ..invalidate(memberSearchProvider);
    if (userId != null) {
      _ref.invalidate(profileByIdProvider(userId));
    }
  }

  Future<Connection> request({
    String? userId,
    String? qrPayload,
    String? message,
  }) async {
    final connection = await _repository.request(
      userId: userId,
      qrPayload: qrPayload,
      message: message,
    );
    _refresh(connection.user.userId);
    return connection;
  }

  Future<void> accept(String connectionId, String userId) async {
    await _repository.accept(connectionId);
    _refresh(userId);
  }

  Future<void> decline(String connectionId, String userId) async {
    await _repository.decline(connectionId);
    _refresh(userId);
  }

  Future<void> remove(String connectionId, String userId) async {
    await _repository.remove(connectionId);
    _refresh(userId);
  }

  Future<void> block(String userId) async {
    await _repository.block(userId);
    _refresh(userId);
    _ref
      ..invalidate(savedContactsProvider)
      ..invalidate(blockedUsersProvider);
  }

  Future<void> unblock(String userId) async {
    await _repository.unblock(userId);
    _ref
      ..invalidate(blockedUsersProvider)
      ..invalidate(savedContactsProvider);
  }
}

final connectionActionsProvider = Provider<ConnectionActions>(
  ConnectionActions.new,
);
