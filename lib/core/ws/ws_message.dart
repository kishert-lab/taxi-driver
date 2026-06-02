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
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};
    final payloadSource = json['payload'] ?? json['data'] ?? json['body'];
    return WsMessage(
      event: json['event'] as String? ?? json['type'] as String? ?? '',
      requestId:
          json['request_id'] as String? ?? meta['request_id'] as String? ?? '',
      occurredAt:
          DateTime.tryParse(
            json['occurred_at'] as String? ??
                json['created_at'] as String? ??
                json['timestamp'] as String? ??
                '',
          ) ??
          DateTime.now().toUtc(),
      payload:
          Map<String, dynamic>.from(
                payloadSource is Map
                    ? payloadSource
                    : const <String, dynamic>{},
              )
              as T,
    );
  }
}
