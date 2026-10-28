import '../../profile/data/profile_models.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String,
    senderId: json['senderId'] as String,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.user,
    required this.unreadCount,
    required this.canSend,
    required this.updatedAt,
    this.lastMessage,
    this.otherLastReadAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    user: Profile.fromJson(json['user'] as Map<String, dynamic>),
    lastMessage: json['lastMessage'] == null
        ? null
        : ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>),
    unreadCount: json['unreadCount'] as int,
    otherLastReadAt: json['otherLastReadAt'] == null
        ? null
        : DateTime.parse(json['otherLastReadAt'] as String),
    canSend: json['canSend'] as bool,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final String id;

  /// The other participant.
  final Profile user;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime? otherLastReadAt;

  /// False once the users are no longer connected (history stays readable).
  final bool canSend;
  final DateTime updatedAt;
}

class MessagePage {
  const MessagePage({
    required this.messages,
    this.nextCursor,
    this.otherLastReadAt,
  });

  factory MessagePage.fromJson(Map<String, dynamic> json) => MessagePage(
    messages: (json['messages'] as List<dynamic>)
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList(),
    nextCursor: json['nextCursor'] as String?,
    otherLastReadAt: json['otherLastReadAt'] == null
        ? null
        : DateTime.parse(json['otherLastReadAt'] as String),
  );

  /// Newest first.
  final List<ChatMessage> messages;
  final String? nextCursor;
  final DateTime? otherLastReadAt;
}
