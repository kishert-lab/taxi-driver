import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_token_storage.dart';
import 'ws_connection_state.dart';
import 'ws_message.dart';

final wsClientProvider = StateNotifierProvider<WsClient, WsConnectionSnapshot>((
  ref,
) {
  return WsClient(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
  );
});

class WsClient extends StateNotifier<WsConnectionSnapshot> {
  WsClient({
    required AppConfig config,
    required SecureTokenStorage tokenStorage,
  }) : _config = config,
       _tokenStorage = tokenStorage,
       super(const WsConnectionSnapshot.disconnected());

  final AppConfig _config;
  final SecureTokenStorage _tokenStorage;
  final _messageController = StreamController<WsMessage>.broadcast();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  var _reconnectAttempt = 0;
  var _manualClose = false;
  var _connecting = false;
  _WsAuthMode? _authMode;
  String? _lastAccessToken;

  Stream<WsMessage> get messages => _messageController.stream;

  Future<void> connect({bool retryingAfterRefresh = false}) async {
    if (_connecting || state.status == WsConnectionStatus.connected) {
      return;
    }

    _manualClose = false;
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      _log('ws no access token, skip connect');
      state = const WsConnectionSnapshot.disconnected();
      return;
    }
    _lastAccessToken = accessToken;

    _connecting = true;
    _reconnectTimer?.cancel();
    state = WsConnectionSnapshot(
      status: retryingAfterRefresh
          ? WsConnectionStatus.reconnecting
          : WsConnectionStatus.connecting,
    );
    _log('ws connecting');

    try {
      await _replaceSocket(
        await WebSocket.connect(
          _config.websocketUrl,
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
        authMode: _WsAuthMode.header,
      );
    } catch (headerError) {
      _log('ws header connect failed: $headerError');
      if (_isUnauthorized(headerError)) {
        _markUnauthorized();
        return;
      }

      try {
        await _replaceSocket(
          await WebSocket.connect('${_config.websocketUrl}?token=$accessToken'),
          authMode: _WsAuthMode.query,
        );
      } catch (queryError) {
        _log('ws query token connect failed: $queryError');
        if (_isUnauthorized(queryError)) {
          _markUnauthorized();
          return;
        }
        _scheduleReconnect();
      }
    } finally {
      _connecting = false;
    }
  }

  Future<void> closeManually() async {
    _manualClose = true;
    _reconnectTimer?.cancel();
    await _closeSocket();
    state = const WsConnectionSnapshot.disconnected();
    _log('ws closed manually');
  }

  Future<void> _replaceSocket(
    WebSocket socket, {
    required _WsAuthMode authMode,
  }) async {
    await _closeSocket();
    _socket = socket;
    _authMode = authMode;
    _socket!.pingInterval = const Duration(seconds: 30);
    _subscription = _socket!.listen(
      _handleRawMessage,
      onError: _handleSocketError,
      onDone: _handleSocketClosed,
      cancelOnError: false,
    );
    _reconnectAttempt = 0;
    state = const WsConnectionSnapshot(status: WsConnectionStatus.connected);
    _log('ws connected');
  }

  void _handleRawMessage(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String);
      final message = WsMessage.fromJson(Map<String, dynamic>.from(decoded));
      _log('ws message received: ${message.event}');
      _messageController.add(message);
    } catch (error) {
      _log('ws malformed message: $error');
    }
  }

  void _handleSocketError(Object error) {
    _log('ws error: $error');
    if (_isUnauthorized(error)) {
      _markUnauthorized();
      return;
    }
    _scheduleReconnect();
  }

  void _handleSocketClosed() {
    _log('ws closed');
    if (_manualClose) {
      state = const WsConnectionSnapshot.disconnected();
      return;
    }
    if (_authMode == _WsAuthMode.header && _lastAccessToken != null) {
      _fallbackToQueryToken();
      return;
    }
    _scheduleReconnect();
  }

  Future<void> _fallbackToQueryToken() async {
    final accessToken = _lastAccessToken;
    if (accessToken == null) {
      _scheduleReconnect();
      return;
    }

    _log('ws fallback to query token');
    try {
      await _replaceSocket(
        await WebSocket.connect('${_config.websocketUrl}?token=$accessToken'),
        authMode: _WsAuthMode.query,
      );
    } catch (error) {
      _log('ws query fallback failed: $error');
      if (_isUnauthorized(error)) {
        _markUnauthorized();
        return;
      }
      _scheduleReconnect();
    }
  }

  void _markUnauthorized() {
    _log('ws unauthorized');
    state = const WsConnectionSnapshot(status: WsConnectionStatus.unauthorized);
  }

  void _scheduleReconnect() {
    if (_manualClose) {
      state = const WsConnectionSnapshot.disconnected();
      return;
    }

    _reconnectTimer?.cancel();
    final delay = _reconnectDelay(_reconnectAttempt);
    _reconnectAttempt++;
    state = WsConnectionSnapshot(
      status: WsConnectionStatus.reconnecting,
      nextReconnectIn: delay,
    );
    _log('ws reconnect scheduled in ${delay.inSeconds}s');
    _reconnectTimer = Timer(delay, () {
      state = const WsConnectionSnapshot(
        status: WsConnectionStatus.disconnected,
      );
      connect();
    });
  }

  Duration _reconnectDelay(int attempt) {
    const seconds = [1, 2, 5, 10, 30];
    return Duration(seconds: seconds[attempt.clamp(0, seconds.length - 1)]);
  }

  Future<void> _closeSocket() async {
    await _subscription?.cancel();
    await _socket?.close();
    _subscription = null;
    _socket = null;
    _authMode = null;
  }

  bool _isUnauthorized(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('401') ||
        text.contains('unauthorized') ||
        text.contains('rejected');
  }

  void _log(String message) {
    // ignore: avoid_print
    print(message);
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _socket?.close();
    _messageController.close();
    super.dispose();
  }
}

enum _WsAuthMode { header, query }
