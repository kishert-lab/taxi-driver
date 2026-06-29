import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/driver_location_outbox_store.dart';

abstract class LocationRepository {
  Future<void> send(DriverLocationSample location);
  Future<void> sendRouteBatch(
    String orderId,
    List<DriverLocationSample> points,
  );
  Future<void> enqueueRoutePoint(String orderId, DriverLocationSample location);
  Future<String?> readOldestRouteOrderId();
  Future<List<QueuedOrderRoutePoint>> readRoutePoints(
    String orderId, {
    required int limit,
  });
  Future<void> deleteRoutePoints(List<int> ids);
  Future<void> clearPendingRoutes();
}

class TaxiLocationRepository implements LocationRepository {
  TaxiLocationRepository(this._apiClient, this._outboxStore);

  final ApiClient _apiClient;
  final DriverLocationOutboxStore _outboxStore;

  @override
  Future<void> send(DriverLocationSample location) {
    return _apiClient.post(
      '/driver/location',
      data: location.toOnlineJson(),
      parser: (_) {},
    );
  }

  @override
  Future<void> sendRouteBatch(
    String orderId,
    List<DriverLocationSample> points,
  ) {
    return _apiClient.post(
      ApiEndpoints.driverOrderRouteBatch(orderId),
      data: {'points': points.map((item) => item.toRouteJson()).toList()},
      parser: (_) {},
    );
  }

  @override
  Future<void> enqueueRoutePoint(
    String orderId,
    DriverLocationSample location,
  ) async {
    await _outboxStore.enqueueRoutePoint(orderId, location);
  }

  @override
  Future<String?> readOldestRouteOrderId() {
    return _outboxStore.readOldestRouteOrderId();
  }

  @override
  Future<List<QueuedOrderRoutePoint>> readRoutePoints(
    String orderId, {
    required int limit,
  }) {
    return _outboxStore.readRoutePoints(orderId, limit: limit);
  }

  @override
  Future<void> deleteRoutePoints(List<int> ids) {
    return _outboxStore.deleteByIds(ids);
  }

  @override
  Future<void> clearPendingRoutes() {
    return _outboxStore.clear();
  }
}

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => TaxiLocationRepository(
    ref.watch(apiClientProvider),
    ref.watch(driverLocationOutboxStoreProvider),
  ),
);
