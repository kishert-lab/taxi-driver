import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/api_client.dart';
import '../domain/driver_profile.dart';

abstract class DriverRepository {
  Future<DriverProfile> getProfile();
  Future<List<DriverCar>> getCars();
  Future<DriverProfile> updateProfile({
    String? name,
    String? licenseNumber,
    String? photoUrl,
  });
  Future<DriverProfile> goOnline();
  Future<DriverProfile> goOffline();
}

class TaxiDriverRepository implements DriverRepository {
  TaxiDriverRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<DriverProfile> getProfile() async {
    final profile = await _apiClient.get(
      '/driver/profile',
      parser: (json) => DriverProfile.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
    final cars = await _getCarsSafely();
    return profile.copyWith(cars: cars);
  }

  Future<List<DriverCar>> _getCarsSafely() async {
    try {
      return await getCars();
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.isNotImplemented) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<List<DriverCar>> getCars() {
    return _apiClient.get(
      '/driver/cars',
      parser: (json) {
        final payload = Map<String, dynamic>.from(json as Map? ?? const {});
        final cars = payload['cars'] as List? ?? const [];
        return cars
            .whereType<Map>()
            .map((item) => DriverCar.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false);
      },
    );
  }

  @override
  Future<DriverProfile> updateProfile({
    String? name,
    String? licenseNumber,
    String? photoUrl,
  }) {
    return _apiClient.patch(
      '/driver/profile',
      data: {
        if (name != null) 'name': name,
        if (licenseNumber != null) 'license_number': licenseNumber,
        if (photoUrl != null) 'photo_url': photoUrl,
      },
      parser: (json) => DriverProfile.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
  }

  @override
  Future<DriverProfile> goOnline() {
    return _apiClient.post(
      '/driver/online',
      parser: (json) => DriverProfile.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
  }

  @override
  Future<DriverProfile> goOffline() {
    return _apiClient.post(
      '/driver/offline',
      parser: (json) => DriverProfile.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
  }
}

final driverRepositoryProvider = Provider<DriverRepository>(
  (ref) => TaxiDriverRepository(ref.watch(apiClientProvider)),
);
