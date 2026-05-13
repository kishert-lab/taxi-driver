import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class DriverShiftRepository {
  DriverShiftRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> goOnline() async {
    await _apiClient.post<void>(ApiEndpoints.driverOnline);
  }

  Future<void> goOffline() async {
    await _apiClient.post<void>(ApiEndpoints.driverOffline);
  }
}
