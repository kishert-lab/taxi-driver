import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ws/ws_client.dart';
import '../../core/ws/ws_connection_state.dart';
import '../../core/ws/ws_message.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/auth_controller.dart';
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
    await _ref.read(wsClientProvider.notifier).connect();
  }

  Future<void> stop() async {
    state = const RealtimeState.stopped();
    _refreshRetried = false;
    await _ref.read(wsClientProvider.notifier).closeManually();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && this.state.started) {
      _log('app resumed, reconnect ws and sync current order');
      _ref.read(wsClientProvider.notifier).connect();
      _syncCurrentOrder();
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
      return;
    }
    if (next.status == WsConnectionStatus.unauthorized) {
      _handleUnauthorized();
    }
  }

  Future<void> _handleUnauthorized() async {
    if (_refreshRetried) {
      _log('token refresh failure');
      await _ref.read(authRepositoryProvider).clearSession();
      _ref.read(authControllerProvider.notifier).forceLogout();
      await stop();
      return;
    }

    _refreshRetried = true;
    _log('ws unauthorized');
    try {
      await _ref.read(authRepositoryProvider).refresh();
      _log('token refresh success');
      await _ref
          .read(wsClientProvider.notifier)
          .connect(retryingAfterRefresh: true);
    } catch (error) {
      _log('token refresh failure: $error');
      await _ref.read(authRepositoryProvider).clearSession();
      _ref.read(authControllerProvider.notifier).forceLogout();
      await stop();
    }
  }

  void _handleMessage(WsMessage message) {
    final type = RealtimeEventTypeX.fromWire(message.event);
    switch (type) {
      case RealtimeEventType.syncRequired:
        _syncCurrentOrder();
      case RealtimeEventType.orderOffer:
        _ref.read(orderOfferProvider.notifier).state = OrderOffer.fromPayload({
          ...message.payload,
          'occurred_at': message.occurredAt.toIso8601String(),
        });
      case RealtimeEventType.orderOfferExpired:
      case RealtimeEventType.orderOfferCancelled:
        _ref.read(orderOfferProvider.notifier).state = null;
        _syncCurrentOrder();
      case RealtimeEventType.orderAccepted:
        _ref.read(orderOfferProvider.notifier).state = null;
        _syncCurrentOrder();
      case RealtimeEventType.orderCancelled:
      case RealtimeEventType.passengerCancelled:
        _ref.read(orderOfferProvider.notifier).state = null;
        _syncCurrentOrder();
      case RealtimeEventType.driverLocationUpdated:
        break;
      case RealtimeEventType.unknown:
        _log('unknown ws event: ${message.event}');
    }
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

  void _handleStreamError(Object error) {
    state = RealtimeState(started: state.started, lastError: '$error');
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
