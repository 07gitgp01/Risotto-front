import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/features/admin/data/admin_models.dart';
import 'package:risotto/features/admin/data/admin_repository.dart';

const testAdminStats = AdminStats(
  members: 12,
  suspended: 1,
  newMembersLast7Days: 3,
  membersWithProfile: 10,
  acceptedConnections: 8,
  pendingConnections: 2,
  conversations: 5,
  messagesLast7Days: 42,
);

AdminAccount adminAccount(
  String id, {
  String? name,
  bool isAdmin = false,
  bool suspended = false,
}) => AdminAccount(
  id: id,
  email: '$id@example.com',
  isAdmin: isAdmin,
  name: name,
  createdAt: DateTime(2026, 3, 4),
  suspendedAt: suspended ? DateTime(2026, 5, 1) : null,
);

/// In-memory AdminRepository: filters like the API and records every call.
class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({List<AdminAccount>? accounts})
    : stored =
          accounts ??
          [
            adminAccount('user-1', name: 'Alice Martin', isAdmin: true),
            adminAccount('bob', name: 'Bob Durand'),
            adminAccount('carol', name: 'Carol Petit', suspended: true),
            adminAccount('newbie'),
          ];

  List<AdminAccount> stored;
  ApiException? failWith;
  final List<String> calls = [];

  @override
  Future<AdminStats> stats() async {
    calls.add('stats');
    if (failWith case final failure?) {
      throw failure;
    }
    return testAdminStats;
  }

  @override
  Future<AdminAccountPage> accounts({
    String query = '',
    AccountFilter filter = AccountFilter.all,
    int offset = 0,
  }) async {
    calls.add('accounts:$query:${filter.name}:$offset');
    if (failWith case final failure?) {
      throw failure;
    }
    final term = query.trim().toLowerCase();
    final matching = stored.where((account) {
      final text = '${account.name ?? ''} ${account.email}'.toLowerCase();
      return text.contains(term) &&
          switch (filter) {
            AccountFilter.all => true,
            AccountFilter.active => !account.isSuspended,
            AccountFilter.suspended => account.isSuspended,
          };
    }).toList();
    return AdminAccountPage(
      total: matching.length,
      items: matching.skip(offset).toList(),
    );
  }

  @override
  Future<void> suspend(String userId) async => _set(userId, DateTime.now());

  @override
  Future<void> reactivate(String userId) async => _set(userId, null);

  void _set(String userId, DateTime? suspendedAt) {
    calls.add('${suspendedAt == null ? 'reactivate' : 'suspend'}:$userId');
    stored = [
      for (final account in stored)
        account.id == userId
            ? account.copyWith(suspendedAt: suspendedAt)
            : account,
    ];
  }
}
