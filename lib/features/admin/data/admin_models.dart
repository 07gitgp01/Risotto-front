class AdminStats {
  const AdminStats({
    required this.members,
    required this.suspended,
    required this.newMembersLast7Days,
    required this.membersWithProfile,
    required this.acceptedConnections,
    required this.pendingConnections,
    required this.conversations,
    required this.messagesLast7Days,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final members = json['members'] as Map<String, dynamic>;
    final connections = json['connections'] as Map<String, dynamic>;
    final messaging = json['messaging'] as Map<String, dynamic>;
    return AdminStats(
      members: members['total'] as int,
      suspended: members['suspended'] as int,
      newMembersLast7Days: members['newLast7Days'] as int,
      membersWithProfile: members['withProfile'] as int,
      acceptedConnections: connections['accepted'] as int,
      pendingConnections: connections['pending'] as int,
      conversations: messaging['conversations'] as int,
      messagesLast7Days: messaging['messagesLast7Days'] as int,
    );
  }

  final int members;
  final int suspended;
  final int newMembersLast7Days;
  final int membersWithProfile;
  final int acceptedConnections;
  final int pendingConnections;
  final int conversations;
  final int messagesLast7Days;
}

enum AccountFilter { all, active, suspended }

class AdminAccount {
  const AdminAccount({
    required this.id,
    required this.email,
    required this.isAdmin,
    required this.name,
    required this.createdAt,
    required this.suspendedAt,
  });

  factory AdminAccount.fromJson(Map<String, dynamic> json) => AdminAccount(
    id: json['id'] as String,
    email: json['email'] as String,
    isAdmin: json['role'] == 'admin',
    name: json['name'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    suspendedAt: switch (json['suspendedAt']) {
      final String value => DateTime.parse(value),
      _ => null,
    },
  );

  final String id;
  final String email;
  final bool isAdmin;

  /// Null when the member has not created a profile yet.
  final String? name;
  final DateTime createdAt;
  final DateTime? suspendedAt;

  bool get isSuspended => suspendedAt != null;

  AdminAccount copyWith({required DateTime? suspendedAt}) => AdminAccount(
    id: id,
    email: email,
    isAdmin: isAdmin,
    name: name,
    createdAt: createdAt,
    suspendedAt: suspendedAt,
  );
}

class AdminAccountPage {
  const AdminAccountPage({required this.total, required this.items});

  factory AdminAccountPage.fromJson(Map<String, dynamic> json) =>
      AdminAccountPage(
        total: json['total'] as int,
        items: [
          for (final item in json['items'] as List<dynamic>)
            AdminAccount.fromJson(item as Map<String, dynamic>),
        ],
      );

  final int total;
  final List<AdminAccount> items;
}
