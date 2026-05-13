import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/models/driver_models.dart';

class DriverProfileRepository {
  DriverProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DriverProfile> getProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.driverProfile,
    );
    return _mapProfile(ApiResponse.data(response.data));
  }

  Future<DriverProfile> updateProfile({
    required String name,
    String? licenseNumber,
    String? photoUrl,
  }) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.driverProfile,
      data: {
        'name': name,
        if (licenseNumber != null) 'license_number': licenseNumber,
        if (photoUrl != null) 'photo_url': photoUrl,
      },
    );
    return _mapProfile(ApiResponse.data(response.data));
  }

  DriverProfile _mapProfile(Map<String, dynamic> json) {
    final isVerified = json['is_verified'] == true;
    final status = (json['status'] as String?) ?? 'offline';

    return DriverProfile(
      id: json['id'] as String? ?? '',
      fullName: json['name'] as String? ?? 'Водитель',
      phone: json['phone'] as String? ?? '',
      email: '',
      city: '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      status: isVerified
          ? DriverVerificationStatus.verified
          : DriverVerificationStatus.pendingVerification,
      workStatus: _mapWorkStatus(status),
      completedTrips: json['ratings_count'] as int? ?? 0,
      registeredAt: DateTime.now().toUtc(),
    );
  }

  DriverWorkStatus _mapWorkStatus(String status) {
    return switch (status) {
      'online' => DriverWorkStatus.online,
      'busy' => DriverWorkStatus.busy,
      'offline' => DriverWorkStatus.offline,
      'blocked' => DriverWorkStatus.blocked,
      _ => DriverWorkStatus.offline,
    };
  }
}
