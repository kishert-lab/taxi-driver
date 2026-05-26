import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/utils/async_state.dart';
import '../data/orders_repository.dart';
import '../domain/driver_order.dart';

final currentOrderProvider =
    StateNotifierProvider<CurrentOrderController, Loadable<DriverOrder>>((ref) {
      return CurrentOrderController(ref.watch(ordersRepositoryProvider));
    });

final orderHistoryProvider =
    StateNotifierProvider<OrderHistoryController, Loadable<List<DriverOrder>>>((
      ref,
    ) {
      return OrderHistoryController(ref.watch(ordersRepositoryProvider));
    });

final orderOfferProvider = StateProvider<OrderOffer?>((ref) => null);

class CurrentOrderController extends StateNotifier<Loadable<DriverOrder>> {
  CurrentOrderController(this._repository) : super(const Loadable.idle());

  final OrdersRepository _repository;

  Future<void> sync() async {
    state = Loadable.loading(state.value);
    try {
      final order = await _repository.currentOrder();
      state = Loadable.idle(order);
    } on ApiException catch (error) {
      if (error.code == 'ORDER_NOT_FOUND' || error.statusCode == 404) {
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
    state = Loadable.idle(await _repository.accept(orderId));
  }

  Future<void> reject(String orderId, String reason) async {
    await _repository.reject(orderId, reason);
    state = const Loadable.idle();
  }

  Future<void> arrived(String orderId) async {
    state = Loadable.idle(await _repository.arrived(orderId));
  }

  Future<void> start(String orderId) async {
    state = Loadable.idle(await _repository.start(orderId));
  }

  Future<void> complete(DriverOrder order) async {
    state = Loadable.idle(
      await _repository.complete(order.orderId, order.price),
    );
  }

  void applyOrder(DriverOrder? order) {
    state = Loadable.idle(order);
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
    final orders = await _repository.history(offset: _offset);
    _offset += orders.length;
    state = Loadable.idle([...current, ...orders]);
  }
}
