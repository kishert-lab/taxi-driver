enum WsConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  unauthorized,
}

class WsConnectionSnapshot {
  const WsConnectionSnapshot({
    required this.status,
    this.message,
    this.nextReconnectIn,
  });

  const WsConnectionSnapshot.disconnected()
    : this(status: WsConnectionStatus.disconnected);

  final WsConnectionStatus status;
  final String? message;
  final Duration? nextReconnectIn;

  bool get isConnected => status == WsConnectionStatus.connected;

  String get label {
    return switch (status) {
      WsConnectionStatus.connected => 'Онлайн',
      WsConnectionStatus.connecting => 'Подключение',
      WsConnectionStatus.reconnecting => 'Переподключение',
      WsConnectionStatus.unauthorized => 'Нет авторизации',
      WsConnectionStatus.disconnected => 'Нет соединения',
    };
  }
}
