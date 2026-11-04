import '../../profile/data/profile_models.dart';

/// Delivery of a message written on this device.
enum SendStatus {
  /// Stored by the server.
  sent,

  /// Waiting for the server's answer.
  sending,

  /// Not stored (offline, error): can be retried with the same client id.
  failed,
}

/// The quoted message above a reply.
class MessagePreview {
  const MessagePreview({
    required this.id,
    required this.senderId,
    required this.body,
    this.deleted = false,
  });

  factory MessagePreview.fromJson(Map<String, dynamic> json) => MessagePreview(
    id: json['id'] as String,
    senderId: json['senderId'] as String,
    body: json['body'] as String,
    deleted: json['deleted'] as bool? ?? false,
  );

  final String id;
  final String senderId;
  final String body;
  final bool deleted;
}

class Reaction {
  const Reaction({required this.emoji, required this.userId});

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
    emoji: json['emoji'] as String,
    userId: json['userId'] as String,
  );

  final String emoji;
  final String userId;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.editedAt,
    this.deleted = false,
    this.replyTo,
    this.reactions = const [],
    this.clientId,
    this.status = SendStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String,
    senderId: json['senderId'] as String,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    editedAt: json['editedAt'] == null
        ? null
        : DateTime.parse(json['editedAt'] as String),
    deleted: json['deleted'] as bool? ?? false,
    replyTo: json['replyTo'] == null
        ? null
        : MessagePreview.fromJson(json['replyTo'] as Map<String, dynamic>),
    reactions: (json['reactions'] as List<dynamic>? ?? const [])
        .map((r) => Reaction.fromJson(r as Map<String, dynamic>))
        .toList(),
    clientId: json['clientId'] as String?,
  );

  /// Server id, or `local-<clientId>` until the server stored it.
  final String id;
  final String conversationId;
  final String senderId;

  /// Empty when deleted.
  final String body;
  final DateTime createdAt;
  final DateTime? editedAt;

  /// Deleted for everyone.
  final bool deleted;
  final MessagePreview? replyTo;
  final List<Reaction> reactions;

  /// Chosen by the sending device; makes retries safe.
  final String? clientId;
  final SendStatus status;

  bool get isLocal => status != SendStatus.sent;

  /// One line for conversation lists.
  String get previewText => deleted ? 'Message supprimé' : body;

  String? reactionOf(String userId) =>
      reactions.where((r) => r.userId == userId).firstOrNull?.emoji;

  ChatMessage copyWith({SendStatus? status}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    body: body,
    createdAt: createdAt,
    editedAt: editedAt,
    deleted: deleted,
    replyTo: replyTo,
    reactions: reactions,
    clientId: clientId,
    status: status ?? this.status,
  );
}

/// The other participant's online status, null when hidden by either side.
class Presence {
  const Presence({required this.online, this.lastSeenAt});

  factory Presence.fromJson(Map<String, dynamic> json) => Presence(
    online: json['online'] as bool,
    lastSeenAt: json['lastSeenAt'] == null
        ? null
        : DateTime.parse(json['lastSeenAt'] as String),
  );

  final bool online;
  final DateTime? lastSeenAt;
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
    this.presence,
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
    presence: json['presence'] == null
        ? null
        : Presence.fromJson(json['presence'] as Map<String, dynamic>),
    canSend: json['canSend'] as bool,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final String id;

  /// The other participant.
  final Profile user;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime? otherLastReadAt;
  final Presence? presence;

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
