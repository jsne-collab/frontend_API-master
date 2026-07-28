class MessagePerson {
  const MessagePerson({required this.id, required this.name, this.role});

  factory MessagePerson.fromJson(Map<String, dynamic> json) {
    return MessagePerson(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['role'] as String?,
    );
  }

  final int id;
  final String name;
  final String? role;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.receiver,
    this.leaseId,
    this.propertyId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      sender: MessagePerson.fromJson(json['sender'] as Map<String, dynamic>),
      receiver: MessagePerson.fromJson(
        json['receiver'] as Map<String, dynamic>,
      ),
      leaseId: json['lease_id'] as int?,
      propertyId: json['property_id'] as int?,
      content: json['content'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final MessagePerson sender;
  final MessagePerson receiver;
  final int? leaseId;
  final int? propertyId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
}

class Conversation {
  const Conversation({
    required this.user,
    required this.lastMessageContent,
    required this.lastMessageSenderId,
    required this.lastMessageIsRead,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final lastMessage = json['last_message'] as Map<String, dynamic>;

    return Conversation(
      user: MessagePerson.fromJson(json['user'] as Map<String, dynamic>),
      lastMessageContent: lastMessage['content'] as String,
      lastMessageSenderId: lastMessage['sender_id'] as int,
      lastMessageIsRead: lastMessage['is_read'] as bool,
      lastMessageAt: DateTime.parse(lastMessage['created_at'] as String),
      unreadCount: json['unread_count'] as int,
    );
  }

  final MessagePerson user;
  final String lastMessageContent;
  final int lastMessageSenderId;
  final bool lastMessageIsRead;
  final DateTime lastMessageAt;
  final int unreadCount;
}
