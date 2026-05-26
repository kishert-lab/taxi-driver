import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/driver_order.dart';

abstract class OrdersRepository {
  Future<DriverOrder?> currentOrder();
  Future<List<DriverOrder>> history({int limit = 20, int offset = 0});
  Future<DriverOrder> accept(String orderId);
  Future<void> reject(String orderId, String reason);
  Future<DriverOrder> arrived(String orderId);
  Future<DriverOrder> start(String orderId);
  Future<DriverOrder> complete(String orderId, Money finalPrice);
  Future<DriverOrder> ratePassenger(String orderId, int score, String comment);
}

class TaxiOrdersRepository implements OrdersRepository {
  TaxiOrdersRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<DriverOrder?> currentOrder() {
    return _apiClient.get(
      '/driver/orders/current',
      parser: (json) {
        if (json == null) {
          return null;
        }
        return DriverOrder.fromJson(Map<String, dynamic>.from(json as Map));
      },
    );
  }

  @override
  Future<List<DriverOrder>> history({int limit = 20, int offset = 0}) {
    return _apiClient.get(
      '/driver/orders/history',
      queryParameters: {'limit': limit, 'offset': offset},
      parser: (json) {
        final payload = Map<String, dynamic>.from(json as Map? ?? const {});
        final orders = payload['orders'] as List? ?? const [];
        return orders
            .whereType<Map>()
            .map(
              (item) => DriverOrder.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
      },
    );
  }

  @override
  Future<DriverOrder> accept(String orderId) {
    return _orderPost('/driver/orders/$orderId/accept');
  }

  @override
  Future<void> reject(String orderId, String reason) {
    return _apiClient.post(
      '/driver/orders/$orderId/reject',
      data: {'reason': reason},
      parser: (_) {},
    );
  }

  @override
  Future<DriverOrder> arrived(String orderId) {
    return _orderPost('/driver/orders/$orderId/arrived');
  }

  @override
  Future<DriverOrder> start(String orderId) {
    return _orderPost('/driver/orders/$orderId/start');
  }

  @override
  Future<DriverOrder> complete(String orderId, Money finalPrice) {
    return _orderPost(
      '/driver/orders/$orderId/complete',
      data: {'final_price': finalPrice.amount, 'currency': finalPrice.currency},
    );
  }

  @override
  Future<DriverOrder> ratePassenger(String orderId, int score, String comment) {
    return _orderPost(
      '/driver/orders/$orderId/rate-passenger',
      data: {'score': score, 'comment': comment},
    );
  }

  Future<DriverOrder> _orderPost(String path, {Object? data}) {
    return _apiClient.post(
      path,
      data: data,
      parser: (json) =>
          DriverOrder.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => TaxiOrdersRepository(ref.watch(apiClientProvider)),
);
