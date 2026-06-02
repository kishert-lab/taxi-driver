import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/driver_order.dart';

abstract class OrdersRepository {
  Future<DriverOrder?> currentOrder();
  Future<List<OrderOffer>> offers();
  Future<List<DriverOrder>> history({int limit = 20, int offset = 0});
  Future<DriverOrder> orderById(String orderId);
  Future<DriverRoute> routeByOrderId(String orderId);
  Future<DriverOrder> accept(String orderId);
  Future<void> reject(String orderId, String reason);
  Future<DriverOrder> arriving(String orderId);
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
      ApiEndpoints.driverCurrentOrder,
      parser: (json) {
        if (json == null) {
          return null;
        }
        return DriverOrder.fromJson(Map<String, dynamic>.from(json as Map));
      },
    );
  }

  @override
  Future<List<OrderOffer>> offers() {
    return _apiClient.get(
      '/driver/orders/offers',
      parser: (json) {
        final payload = Map<String, dynamic>.from(json as Map? ?? const {});
        final offers = payload['offers'] as List? ?? const [];
        return offers
            .whereType<Map>()
            .map(
              (item) => OrderOffer.fromPayload(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
      },
    );
  }

  @override
  Future<List<DriverOrder>> history({int limit = 20, int offset = 0}) {
    return _apiClient.get(
      ApiEndpoints.driverOrdersHistory,
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
  Future<DriverOrder> orderById(String orderId) {
    return _apiClient.get(
      ApiEndpoints.driverOrder(orderId),
      parser: (json) => DriverOrder.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
  }

  @override
  Future<DriverRoute> routeByOrderId(String orderId) {
    return _apiClient.get(
      ApiEndpoints.driverOrderRoute(orderId),
      parser: (json) => DriverRoute.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
  }

  @override
  Future<DriverOrder> accept(String orderId) {
    return _orderPost(ApiEndpoints.driverAcceptOrder(orderId));
  }

  @override
  Future<void> reject(String orderId, String reason) {
    return _apiClient.post(
      ApiEndpoints.driverRejectOrder(orderId),
      data: {'reason': reason},
      parser: (_) {},
    );
  }

  @override
  Future<DriverOrder> arriving(String orderId) {
    return _orderPost('/driver/orders/$orderId/arriving');
  }

  @override
  Future<DriverOrder> arrived(String orderId) {
    return _orderPost(ApiEndpoints.driverArrived(orderId));
  }

  @override
  Future<DriverOrder> start(String orderId) {
    return _orderPost(ApiEndpoints.driverStartTrip(orderId));
  }

  @override
  Future<DriverOrder> complete(String orderId, Money finalPrice) {
    return _orderPost(
      ApiEndpoints.driverCompleteTrip(orderId),
      data: {'final_price': finalPrice.amount, 'currency': finalPrice.currency},
    );
  }

  @override
  Future<DriverOrder> ratePassenger(String orderId, int score, String comment) {
    return _orderPost(
      ApiEndpoints.driverRatePassenger(orderId),
      data: {'score': score, 'comment': comment},
    );
  }

  Future<DriverOrder> _orderPost(String path, {Object? data}) {
    return _apiClient.post(
      path,
      data: data,
      parser: (json) => DriverOrder.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => TaxiOrdersRepository(ref.watch(apiClientProvider)),
);
