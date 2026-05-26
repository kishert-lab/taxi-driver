class WsMessage<T extends Map<String, dynamic>> {
  const WsMessage({
    required this.event,
    required this.requestId,
    required this.occurredAt,
    required this.payload,
  });

  final String event;
  final String requestId;
  final DateTime occurredAt;
  final T payload;

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      event: json['event'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
      occurredAt:
          DateTime.tryParse(json['occurred_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      payload:
          Map<String, dynamic>.from(json['payload'] as Map? ?? const {}) as T,
    );
  }
}
