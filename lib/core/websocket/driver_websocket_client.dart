import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../storage/secure_token_storage.dart';

class DriverWebSocketClient {
  DriverWebSocketClient({
    required AppConfig config,
    required SecureTokenStorage tokenStorage,
  }) : _config = config,
       _tokenStorage = tokenStorage;

  final AppConfig _config;
  final SecureTokenStorage _tokenStorage;
  WebSocketChannel? _channel;
  final _eventsController = StreamController<DriverSocketEvent>.broadcast();

  Stream<DriverSocketEvent> get events => _eventsController.stream;

  Future<void> connect() async {
    final tokens = await _tokenStorage.readTokens();
    if (tokens == null) {
      throw const UnauthorizedException(
        'driver websocket connection requires tokens',
      );
    }

    final uri = Uri.parse(
      _config.websocketUrl,
    ).replace(queryParameters: {'token': tokens.accessToken});
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (message) => _eventsController.add(
        DriverSocketEvent.fromJson(jsonDecode(message as String)),
      ),
      onError: (Object error) => _eventsController.addError(
        NetworkException('driver websocket failed', cause: error),
      ),
      onDone: () => _eventsController.add(
        const DriverSocketEvent(type: 'connection_closed', payload: {}),
      ),
    );
  }

  void send(String type, Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) {
      throw const NetworkException('driver websocket is not connected');
    }

    channel.sink.add(jsonEncode({'type': type, 'payload': payload}));
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }
}

class DriverSocketEvent {
  const DriverSocketEvent({required this.type, required this.payload});

  final String type;
  final Map<String, dynamic> payload;

  factory DriverSocketEvent.fromJson(Map<String, dynamic> json) {
    return DriverSocketEvent(
      type: json['type'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
    );
  }
}
