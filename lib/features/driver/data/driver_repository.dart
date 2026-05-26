import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/driver_profile.dart';

abstract class DriverRepository {
  Future<DriverProfile> getProfile();
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
  Future<DriverProfile> getProfile() {
    return _apiClient.get(
      '/driver/profile',
      parser: (json) => DriverProfile.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
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
