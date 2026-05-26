import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';

abstract class LocationRepository {
  Future<void> send(DriverLocationSample location);
  Future<void> sendBatch(List<DriverLocationSample> locations);
}

class TaxiLocationRepository implements LocationRepository {
  TaxiLocationRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> send(DriverLocationSample location) {
    return _apiClient.post(
      '/driver/location',
      data: location.toJson(),
      parser: (_) {},
    );
  }

  @override
  Future<void> sendBatch(List<DriverLocationSample> locations) {
    return _apiClient.post(
      '/driver/location/batch',
      data: {'locations': locations.map((item) => item.toJson()).toList()},
      parser: (_) {},
    );
  }
}

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => TaxiLocationRepository(ref.watch(apiClientProvider)),
);
