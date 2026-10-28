import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/features/connections/data/connections_models.dart';
import 'package:risotto/features/connections/data/connections_repository.dart';
import 'package:risotto/features/profile/data/profile_models.dart';

Profile member(
  String id,
  String first,
  String last, {
  String? headline,
  MemberConnection connection = const MemberConnection(ConnectionStatus.none),
  ProfileAccess access = ProfileAccess.preview,
}) => Profile(
  userId: id,
  access: access,
  firstName: first,
  lastName: last,
  headline: headline,
  connection: connection,
);

/// In-memory connections backend. Members are searchable by name.
class FakeConnectionsRepository implements ConnectionsRepository {
  FakeConnectionsRepository({List<Profile>? members}) : members = members ?? [];

  final List<Profile> members;
  final List<Connection> all = [];
  final List<BlockedUser> blockedUsers = [];
  final List<String> calls = [];
  Map<String, Object?> lastArgs = {};
  ApiException? failWith;
  int _ids = 0;

  static const _reads = {'search', 'connections', 'requests', 'blocked'};

  Future<T> _run<T>(String name, Map<String, Object?> args, T Function() ok) {
    calls.add(name);
    // Reads re-run after every action: only actions are recorded.
    if (!_reads.contains(name)) {
      lastArgs = args;
    }
    final failure = failWith;
    return failure != null ? Future.error(failure) : Future.value(ok());
  }

  Profile _member(String userId) => members.firstWhere(
    (m) => m.userId == userId,
    orElse: () => member(userId, 'Membre', userId),
  );

  void addIncoming(Profile from, {String? message}) => all.add(
    Connection(
      id: 'c${_ids++}',
      status: 'pending',
      direction: RequestDirection.incoming,
      message: message,
      createdAt: DateTime(2026),
      user: from,
    ),
  );

  void addAccepted(Profile with_) => all.add(
    Connection(
      id: 'c${_ids++}',
      status: 'accepted',
      direction: RequestDirection.outgoing,
      createdAt: DateTime(2026),
      user: with_,
    ),
  );

  MemberConnection _stateWith(String userId) {
    final connection = all.where((c) => c.user.userId == userId).firstOrNull;
    if (connection == null) {
      return const MemberConnection(ConnectionStatus.none);
    }
    if (connection.status == 'accepted') {
      return MemberConnection(ConnectionStatus.connected, connection.id);
    }
    return MemberConnection(
      connection.direction == RequestDirection.incoming
          ? ConnectionStatus.pendingIncoming
          : ConnectionStatus.pendingOutgoing,
      connection.id,
    );
  }

  /// Profile as the API would return it now (with the current connection state).
  Profile current(String userId) {
    final m = _member(userId);
    return member(
      m.userId,
      m.firstName,
      m.lastName,
      headline: m.headline,
      access: m.access,
      connection: _stateWith(userId),
    );
  }

  @override
  Future<List<Profile>> search(String query) =>
      _run('search', {'q': query}, () {
        final q = query.toLowerCase();
        return members
            .where((m) => m.fullName.toLowerCase().contains(q))
            .map((m) => current(m.userId))
            .toList();
      });

  @override
  Future<Connection> request({
    String? userId,
    String? qrPayload,
    String? message,
  }) => _run(
    'request',
    {'userId': userId, 'qrPayload': qrPayload, 'message': message},
    () {
      final target = _member(userId ?? 'scanned');
      final connection = Connection(
        id: 'c${_ids++}',
        status: 'pending',
        direction: RequestDirection.outgoing,
        message: message,
        createdAt: DateTime(2026),
        user: target,
      );
      all.add(connection);
      return connection;
    },
  );

  Connection _replace(String id, String status) {
    final index = all.indexWhere((c) => c.id == id);
    if (index < 0) {
      // Unknown to this fake (e.g. a request shown by the dashboard fake).
      return Connection(
        id: id,
        status: status,
        direction: RequestDirection.incoming,
        createdAt: DateTime(2026),
        user: member('unknown', 'Membre', 'Inconnu'),
      );
    }
    final old = all[index];
    return all[index] = Connection(
      id: old.id,
      status: status,
      direction: old.direction,
      message: old.message,
      createdAt: old.createdAt,
      user: old.user,
    );
  }

  @override
  Future<Connection> accept(String connectionId) => _run('accept', {
    'id': connectionId,
  }, () => _replace(connectionId, 'accepted'));

  @override
  Future<void> decline(String connectionId) => _run('decline', {
    'id': connectionId,
  }, () => all.removeWhere((c) => c.id == connectionId));

  @override
  Future<void> remove(String connectionId) => _run('remove', {
    'id': connectionId,
  }, () => all.removeWhere((c) => c.id == connectionId));

  @override
  Future<List<Connection>> connections() => _run(
    'connections',
    {},
    () => all.where((c) => c.status == 'accepted').toList(),
  );

  @override
  Future<List<Connection>> requests(RequestDirection direction) => _run(
    'requests',
    {'direction': direction},
    () => all
        .where((c) => c.status == 'pending' && c.direction == direction)
        .toList(),
  );

  @override
  Future<void> block(String userId) => _run('block', {'userId': userId}, () {
    all.removeWhere((c) => c.user.userId == userId);
    final m = _member(userId);
    blockedUsers.add(
      BlockedUser(userId: userId, firstName: m.firstName, lastName: m.lastName),
    );
  });

  @override
  Future<void> unblock(String userId) => _run('unblock', {
    'userId': userId,
  }, () => blockedUsers.removeWhere((b) => b.userId == userId));

  @override
  Future<List<BlockedUser>> blocked() =>
      _run('blocked', {}, () => [...blockedUsers]);
}
