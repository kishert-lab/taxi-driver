import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/utils/async_state.dart';
import '../../driver/presentation/location_controller.dart';
import '../data/orders_repository.dart';
import '../domain/driver_order.dart';

class OrderDetailsViewData {
  const OrderDetailsViewData({required this.order, required this.route});

  final DriverOrder order;
  final DriverRoute? route;
}

final currentOrderProvider =
    StateNotifierProvider<CurrentOrderController, Loadable<DriverOrder>>((ref) {
      return CurrentOrderController(
        ref.watch(ordersRepositoryProvider),
        ref.read(locationControllerProvider.notifier),
        onOrderCompleted: () async {
          await ref.read(orderHistoryProvider.notifier).refresh();
        },
      );
    });

final orderHistoryProvider =
    StateNotifierProvider<OrderHistoryController, Loadable<List<DriverOrder>>>((
      ref,
    ) {
      return OrderHistoryController(ref.watch(ordersRepositoryProvider));
    });

final orderDetailsProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailsController, Loadable<OrderDetailsViewData>, String>((
      ref,
      orderId,
    ) {
      return OrderDetailsController(
        ref.watch(ordersRepositoryProvider),
        orderId,
      );
    });

final orderOfferProvider = StateProvider<OrderOffer?>((ref) => null);
final orderOffersSynchronizerProvider = Provider<OrderOffersSynchronizer>((
  ref,
) {
  return OrderOffersSynchronizer(ref);
});

class OrderOffersSynchronizer {
  OrderOffersSynchronizer(this._ref);

  final Ref _ref;
  Future<void>? _syncFuture;

  Future<void> sync() {
    _syncFuture ??= _runSync().whenComplete(() => _syncFuture = null);
    return _syncFuture!;
  }

  Future<void> _runSync() async {
    try {
      await _doSync();
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.isNotImplemented) {
        return;
      }
      _log('offers sync failed: $error');
    } catch (error) {
      _log('offers sync failed: $error');
    }
  }

  Future<void> _doSync() async {
    final currentOrder = _ref.read(currentOrderProvider).value;
    if (currentOrder != null && !currentOrder.isTerminal) {
      _ref.read(orderOfferProvider.notifier).state = null;
      return;
    }

    final offers = await _ref.read(ordersRepositoryProvider).offers();
    final activeOffer = _firstActiveOffer(offers);
    if (activeOffer == null) {
      _ref.read(orderOfferProvider.notifier).state = null;
      return;
    }

    final currentOffer = _ref.read(orderOfferProvider);
    if (currentOffer?.order.orderId == activeOffer.order.orderId) {
      return;
    }
    _ref.read(orderOfferProvider.notifier).state = activeOffer;
  }

  OrderOffer? _firstActiveOffer(List<OrderOffer> offers) {
    final now = DateTime.now().toUtc();
    for (final offer in offers) {
      final expiresAt = offer.expiresAt;
      if (expiresAt == null || expiresAt.isAfter(now)) {
        return offer;
      }
    }
    return null;
  }

  void _log(String message) {
    // ignore: avoid_print
    print(message);
  }
}

class CurrentOrderController extends StateNotifier<Loadable<DriverOrder>> {
  CurrentOrderController(
    this._repository,
    this._locationController, {
    required Future<void> Function() onOrderCompleted,
  }) : _onOrderCompleted = onOrderCompleted,
       super(const Loadable.idle());

  final OrdersRepository _repository;
  final LocationController _locationController;
  final Future<void> Function() _onOrderCompleted;

  Future<void> sync() async {
    state = Loadable.loading(state.value);
    try {
      final order = await _repository.currentOrder();
      state = Loadable.idle(order);
    } on ApiException catch (error) {
      if (error.isOrderNotFound) {
        state = const Loadable.idle();
        return;
      }
      if (error.isNotImplemented) {
        state = Loadable(
          isLoading: false,
          value: state.value,
          errorMessage: 'Текущий заказ недоступен',
        );
        return;
      }
      state = Loadable(
        isLoading: false,
        value: state.value,
        errorMessage: error.userMessage,
      );
    }
  }

  Future<void> accept(String orderId) async {
    await _runOrderAction(() async {
      final acceptedOrder = await _repository.accept(orderId);
      state = Loadable.idle(acceptedOrder);
      try {
        final arrivingOrder = await _repository.arriving(orderId);
        state = Loadable.idle(arrivingOrder);
      } on ApiException {
        state = Loadable.idle(acceptedOrder);
      }
      await sync();
    });
  }

  Future<void> reject(String orderId, String reason) async {
    await _runOrderAction(() async {
      await _repository.reject(orderId, reason);
      state = const Loadable.idle();
    });
  }

  Future<void> arriving(String orderId) async {
    await _runOrderAction(() async {
      state = Loadable.idle(await _repository.arriving(orderId));
      await sync();
    });
  }

  Future<void> arrived(String orderId) async {
    await _runOrderAction(() async {
      state = Loadable.idle(await _repository.arrived(orderId));
      await sync();
    });
  }

  Future<void> start(String orderId) async {
    await _runOrderAction(() async {
      state = Loadable.idle(await _repository.start(orderId));
      await sync();
    });
  }

  Future<void> complete(DriverOrder order) async {
    await _runOrderAction(() async {
      await _locationController.sendLastLocationBeforeComplete(order.orderId);
      await _repository.complete(order.orderId, order.price);
      state = const Loadable.idle();
      await _onOrderCompleted();
      await sync();
      final syncedOrder = state.value;
      if (syncedOrder?.isTerminal == true) {
        state = const Loadable.idle();
      }
    });
  }

  void applyOrder(DriverOrder? order) {
    state = Loadable.idle(order);
  }

  Future<void> _runOrderAction(Future<void> Function() action) async {
    if (state.isLoading) {
      return;
    }
    final previousOrder = state.value;
    state = Loadable.loading(previousOrder);
    try {
      await action();
    } on ApiException catch (error) {
      state = Loadable(
        isLoading: false,
        value: previousOrder,
        errorMessage: error.userMessage,
      );
    } catch (error) {
      state = Loadable(
        isLoading: false,
        value: previousOrder,
        errorMessage: 'Не удалось выполнить действие: $error',
      );
    }
  }
}

class OrderHistoryController
    extends StateNotifier<Loadable<List<DriverOrder>>> {
  OrderHistoryController(this._repository) : super(const Loadable.idle([]));

  final OrdersRepository _repository;
  var _offset = 0;

  Future<void> refresh() async {
    state = Loadable.loading(state.value ?? []);
    try {
      _offset = 0;
      final orders = await _repository.history();
      _offset = orders.length;
      state = Loadable.idle(orders);
    } on ApiException catch (error) {
      state = Loadable(
        isLoading: false,
        value: state.value ?? [],
        errorMessage: error.userMessage,
      );
    }
  }

  Future<void> loadMore() async {
    final current = state.value ?? [];
    try {
      final orders = await _repository.history(offset: _offset);
      _offset += orders.length;
      state = Loadable.idle([...current, ...orders]);
    } on ApiException catch (error) {
      state = Loadable(
        isLoading: false,
        value: current,
        errorMessage: error.userMessage,
      );
    }
  }
}

class OrderDetailsController
    extends StateNotifier<Loadable<OrderDetailsViewData>> {
  OrderDetailsController(this._repository, this._orderId)
    : super(const Loadable.idle());

  final OrdersRepository _repository;
  final String _orderId;

  Future<void> load() async {
    state = Loadable.loading(state.value);
    try {
      final order = await _repository.orderById(_orderId);
      DriverRoute? route;
      try {
        route = await _repository.routeByOrderId(_orderId);
      } on ApiException {
        route = null;
      }
      state = Loadable.idle(OrderDetailsViewData(order: order, route: route));
    } on ApiException catch (error) {
      state = Loadable(
        isLoading: false,
        value: state.value,
        errorMessage: error.userMessage,
      );
    }
  }
}
