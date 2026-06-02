import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error.dart';
import '../../core/ws/ws_client.dart';
import '../../core/ws/ws_connection_state.dart';
import '../../core/ws/ws_message.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/auth_controller.dart';
import '../chat/domain/chat_models.dart';
import '../chat/presentation/chat_controller.dart';
import '../orders/domain/driver_order.dart';
import '../orders/presentation/orders_controllers.dart';
import 'realtime_events.dart';

class RealtimeState {
  const RealtimeState({required this.started, this.lastError});

  const RealtimeState.stopped() : this(started: false);

  final bool started;
  final String? lastError;
}

final realtimeControllerProvider =
    StateNotifierProvider<RealtimeController, RealtimeState>((ref) {
      return RealtimeController(ref);
    });

class RealtimeController extends StateNotifier<RealtimeState>
    with WidgetsBindingObserver {
  RealtimeController(this._ref) : super(const RealtimeState.stopped()) {
    _messageSubscription = _ref
        .read(wsClientProvider.notifier)
        .messages
        .listen(_handleMessage, onError: _handleStreamError);
    _ref.listen<WsConnectionSnapshot>(wsClientProvider, _handleWsState);
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref _ref;
  StreamSubscription<WsMessage>? _messageSubscription;
  Future<void>? _syncFuture;
  DateTime? _lastSyncStartedAt;
  var _refreshRetried = false;

  Future<void> start() async {
    state = const RealtimeState(started: true);
    _refreshRetried = false;
    await _connectSafely();
  }

  Future<void> stop() async {
    state = const RealtimeState.stopped();
    _refreshRetried = false;
    await _ref.read(wsClientProvider.notifier).closeManually();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && this.state.started) {
      _log('app resumed, reconnect ws');
      unawaited(_connectSafely());
    }
  }

  void _handleWsState(
    WsConnectionSnapshot? previous,
    WsConnectionSnapshot next,
  ) {
    if (!state.started) {
      return;
    }
    if (next.status == WsConnectionStatus.connected) {
      _refreshRetried = false;
      _syncCurrentOrder();
      _syncOrderOffers();
      return;
    }
    if (next.status == WsConnectionStatus.unauthorized) {
      _handleUnauthorized();
    }
  }

  Future<void> _handleUnauthorized() async {
    if (_refreshRetried) {
      _log('token refresh failure');
      await _handleSessionRefreshFailure();
      return;
    }

    _refreshRetried = true;
    _log('ws unauthorized');
    try {
      await _ref.read(authRepositoryProvider).refresh();
      _log('token refresh success');
      await _connectSafely(retryingAfterRefresh: true);
    } catch (error) {
      _log('token refresh failure: $error');
      if (error is ApiException && error.isUnauthorized) {
        await _handleSessionRefreshFailure();
        return;
      }
      state = RealtimeState(
        started: state.started,
        lastError: 'Связь с сервером недоступна',
      );
      _refreshRetried = false;
      unawaited(_scheduleReconnectAfterRefreshFailure());
    }
  }

  void _handleMessage(WsMessage message) {
    final type = RealtimeEventTypeX.fromWire(message.event);
    switch (type) {
      case RealtimeEventType.syncRequired:
        _syncCurrentOrder();
        _syncOrderOffers();
      case RealtimeEventType.orderOffer:
        final payload = _normalizeOrderOfferPayload(message);
        _ref.read(orderOfferProvider.notifier).state = OrderOffer.fromPayload(
          payload,
        );
        _syncOrderOffers();
      case RealtimeEventType.orderOfferExpired:
      case RealtimeEventType.orderOfferCancelled:
        _ref.read(orderOfferProvider.notifier).state = null;
        _syncCurrentOrder();
        _syncOrderOffers();
      case RealtimeEventType.orderAccepted:
        _ref.read(orderOfferProvider.notifier).state = null;
        _syncCurrentOrder();
        _syncOrderOffers();
      case RealtimeEventType.orderCancelled:
      case RealtimeEventType.passengerCancelled:
        _ref.read(orderOfferProvider.notifier).state = null;
        _syncCurrentOrder();
        _syncOrderOffers();
      case RealtimeEventType.chatMessage:
        final chatMessage = _normalizeChatMessage(message);
        if (chatMessage != null) {
          _ref.read(chatRealtimeBusProvider).emit(chatMessage);
          _ref
              .read(chatThreadsProvider.notifier)
              .applyIncomingMessage(chatMessage);
        }
      case RealtimeEventType.driverLocationUpdated:
        break;
      case RealtimeEventType.unknown:
        if (_looksLikeChatEvent(message.event)) {
          final chatMessage = _normalizeChatMessage(message);
          if (chatMessage != null) {
            _log('fallback sync for ws chat event: ${message.event}');
            _ref.read(chatRealtimeBusProvider).emit(chatMessage);
            _ref
                .read(chatThreadsProvider.notifier)
                .applyIncomingMessage(chatMessage);
            return;
          }
        }
        if (_looksLikeOrderEvent(message.event)) {
          _log('fallback sync for ws event: ${message.event}');
          _syncCurrentOrder();
          _syncOrderOffers();
          return;
        }
        _log('unknown ws event: ${message.event}');
    }
  }

  Map<String, dynamic> _normalizeOrderOfferPayload(WsMessage message) {
    final payload = Map<String, dynamic>.from(message.payload);
    final order = payload['order'];
    if (order is Map<String, dynamic>) {
      return {
        ...payload,
        ...order,
        'order': order,
        'occurred_at':
            payload['occurred_at'] ?? message.occurredAt.toIso8601String(),
      };
    }
    if (order is Map) {
      final orderMap = Map<String, dynamic>.from(order);
      return {
        ...payload,
        ...orderMap,
        'order': orderMap,
        'occurred_at':
            payload['occurred_at'] ?? message.occurredAt.toIso8601String(),
      };
    }
    return {
      ...payload,
      'occurred_at':
          payload['occurred_at'] ?? message.occurredAt.toIso8601String(),
    };
  }

  bool _looksLikeOrderEvent(String event) {
    final normalized = event.toLowerCase();
    return normalized.contains('order') ||
        normalized.contains('offer') ||
        normalized.contains('trip');
  }

  bool _looksLikeChatEvent(String event) {
    final normalized = event.toLowerCase();
    return normalized.contains('chat') || normalized.contains('message');
  }

  ChatMessage? _normalizeChatMessage(WsMessage message) {
    final payload = Map<String, dynamic>.from(message.payload);
    final source = payload['message'] is Map
        ? Map<String, dynamic>.from(payload['message'] as Map)
        : payload;
    final orderId =
        source['order_id'] as String? ?? payload['order_id'] as String? ?? '';
    final body = source['body'] as String? ?? payload['body'] as String? ?? '';
    if (orderId.isEmpty || body.isEmpty) {
      return null;
    }
    return ChatMessage.fromJson({
      ...payload,
      ...source,
      'order_id': orderId,
      'body': body,
      'created_at':
          source['created_at'] ??
          payload['created_at'] ??
          message.occurredAt.toIso8601String(),
    });
  }

  void _syncCurrentOrder() {
    final now = DateTime.now();
    final lastSyncStartedAt = _lastSyncStartedAt;
    if (_syncFuture != null) {
      return;
    }
    if (lastSyncStartedAt != null &&
        now.difference(lastSyncStartedAt) < const Duration(seconds: 1)) {
      return;
    }

    _lastSyncStartedAt = now;
    _syncFuture = _ref
        .read(currentOrderProvider.notifier)
        .sync()
        .whenComplete(() => _syncFuture = null);
  }

  void _syncOrderOffers() {
    unawaited(_ref.read(orderOffersSynchronizerProvider).sync());
  }

  void _handleStreamError(Object error) {
    state = RealtimeState(started: state.started, lastError: '$error');
  }

  Future<void> _connectSafely({bool retryingAfterRefresh = false}) async {
    try {
      await _ref
          .read(wsClientProvider.notifier)
          .connect(retryingAfterRefresh: retryingAfterRefresh);
    } catch (error) {
      _log('ws connect failed: $error');
      state = RealtimeState(started: state.started, lastError: '$error');
    }
  }

  Future<void> _handleSessionRefreshFailure() async {
    await _ref.read(authRepositoryProvider).clearSession();
    _ref.read(authControllerProvider.notifier).forceLogout();
    await stop();
  }

  Future<void> _scheduleReconnectAfterRefreshFailure() async {
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!state.started) {
      return;
    }
    await _connectSafely(retryingAfterRefresh: true);
  }

  void _log(String message) {
    // ignore: avoid_print
    print(message);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageSubscription?.cancel();
    super.dispose();
  }
}
