import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/features/dashboard/data/dashboard_models.dart';
import 'package:risotto/features/dashboard/data/dashboard_repository.dart';

Map<String, dynamic> _profile(String id, String first) => {
  'userId': id,
  'access': 'preview',
  'firstName': first,
  'lastName': 'Durand',
  'headline': 'Designer',
};

/// A dashboard with one pending request (Carol), one unread conversation (Bob)
/// and two activity items.
Map<String, dynamic> busyDashboardJson() => {
  'pendingRequests': {
    'count': 1,
    'latest': [
      {
        'id': 'req-1',
        'status': 'pending',
        'direction': 'incoming',
        'message': 'Rencontrés au salon',
        'createdAt': DateTime(2026, 1, 1, 8).toIso8601String(),
        'respondedAt': null,
        'user': _profile('carol', 'Carol'),
      },
    ],
  },
  'unreadMessages': {
    'count': 2,
    'conversations': [
      {
        'id': 'conv-1',
        'user': _profile('bob', 'Bob'),
        'lastMessage': {
          'id': 'm2',
          'conversationId': 'conv-1',
          'senderId': 'bob',
          'body': 'Tu es dispo ?',
          'createdAt': DateTime(2026, 1, 1, 9).toIso8601String(),
        },
        'unreadCount': 2,
        'otherLastReadAt': null,
        'canSend': true,
        'updatedAt': DateTime(2026, 1, 1, 9).toIso8601String(),
      },
    ],
  },
  'unreadNotifications': 1,
  'stats': {'connections': 3, 'contacts': 1},
  'recentActivity': [
    {
      'type': 'message',
      'at': DateTime(2026, 1, 1, 9).toIso8601String(),
      'actor': _profile('bob', 'Bob'),
      'data': {'conversationId': 'conv-1'},
    },
    {
      'type': 'connection_request',
      'at': DateTime(2026, 1, 1, 8).toIso8601String(),
      'actor': _profile('carol', 'Carol'),
      'data': {'connectionId': 'req-1'},
    },
  ],
};

Map<String, dynamic> emptyDashboardJson() => {
  'pendingRequests': {'count': 0, 'latest': <dynamic>[]},
  'unreadMessages': {'count': 0, 'conversations': <dynamic>[]},
  'unreadNotifications': 0,
  'stats': {'connections': 0, 'contacts': 0},
  'recentActivity': <dynamic>[],
};

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository([Map<String, dynamic>? json])
    : json = json ?? emptyDashboardJson();

  Map<String, dynamic> json;
  ApiException? failWith;
  int loads = 0;

  @override
  Future<Dashboard> load() async {
    loads++;
    final failure = failWith;
    if (failure != null) {
      throw failure;
    }
    return Dashboard.fromJson(json);
  }
}
