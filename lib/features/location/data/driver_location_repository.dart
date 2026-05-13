import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/driver_models.dart';

class DriverLocationRepository {
  DriverLocationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> sendLocation(DriverLocation location) async {
    await _apiClient.post<void>(
      ApiEndpoints.driverLocation,
      data: _locationPayload(location),
    );
  }

  Future<void> sendLocationBatch(List<DriverLocation> locations) async {
    await _apiClient.post<void>(
      ApiEndpoints.driverLocationBatch,
      data: {
        'locations': locations.map(_locationPayload).toList(growable: false),
      },
    );
  }

  Map<String, dynamic> _locationPayload(DriverLocation location) {
    return {
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'speed_mps': location.speed < 0 ? 0 : location.speed,
      'heading': location.bearing.round().clamp(0, 359),
      'accuracy_meters': location.accuracy < 0 ? 0 : location.accuracy,
    };
  }
}
