class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.orderId,
    required this.senderUserId,
    required this.senderRole,
    required this.chatType,
    required this.body,
    required this.createdAt,
    this.clientId,
    this.isPending = false,
  });

  final String id;
  final String threadId;
  final String orderId;
  final String senderUserId;
  final String senderRole;
  final String chatType;
  final String body;
  final DateTime createdAt;
  final String? clientId;
  final bool isPending;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      threadId: json['thread_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      senderUserId: json['sender_user_id'] as String? ?? '',
      senderRole: json['sender_role'] as String? ?? '',
      chatType: json['chat_type'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0).toUtc(),
    );
  }

  factory ChatMessage.pending({
    required String clientId,
    required String orderId,
    required String body,
    required DateTime createdAt,
  }) {
    return ChatMessage(
      id: '',
      threadId: '',
      orderId: orderId,
      senderUserId: '',
      senderRole: 'driver',
      chatType: 'driver_dispatcher',
      body: body,
      createdAt: createdAt,
      clientId: clientId,
      isPending: true,
    );
  }

  bool get isFromDriver => senderRole == 'driver';

  String get uniqueKey {
    if (id.isNotEmpty) {
      return id;
    }
    return clientId ?? '${senderRole}_${createdAt.toIso8601String()}_$body';
  }

  ChatMessage copyWith({
    String? id,
    String? threadId,
    String? orderId,
    String? senderUserId,
    String? senderRole,
    String? chatType,
    String? body,
    DateTime? createdAt,
    String? clientId,
    bool? isPending,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      orderId: orderId ?? this.orderId,
      senderUserId: senderUserId ?? this.senderUserId,
      senderRole: senderRole ?? this.senderRole,
      chatType: chatType ?? this.chatType,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      clientId: clientId ?? this.clientId,
      isPending: isPending ?? this.isPending,
    );
  }
}

class ChatThread {
  const ChatThread({
    required this.threadId,
    required this.chatType,
    required this.messages,
  });

  final String threadId;
  final String chatType;
  final List<ChatMessage> messages;

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final messages =
        (json['messages'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false)
          ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

    return ChatThread(
      threadId: json['thread_id'] as String? ?? '',
      chatType: json['chat_type'] as String? ?? '',
      messages: messages,
    );
  }
}
