import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';

class DriverOrdersRepository {
  DriverOrdersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getCurrentOrder() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.driverCurrentOrder,
    );
    return ApiResponse.data(response.data);
  }

  Future<List<dynamic>> getOrderHistory() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.driverOrdersHistory,
    );
    return ApiResponse.listField(response.data, 'orders');
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.driverAcceptOrder(orderId),
    );
    return ApiResponse.data(response.data);
  }

  Future<void> rejectOrder(String orderId, String reason) async {
    await _apiClient.post<void>(
      ApiEndpoints.driverRejectOrder(orderId),
      data: {'reason': reason},
    );
  }

  Future<Map<String, dynamic>> arrived(String orderId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.driverArrived(orderId),
    );
    return ApiResponse.data(response.data);
  }

  Future<Map<String, dynamic>> startTrip(String orderId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.driverStartTrip(orderId),
    );
    return ApiResponse.data(response.data);
  }

  Future<Map<String, dynamic>> completeTrip(String orderId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.driverCompleteTrip(orderId),
    );
    return ApiResponse.data(response.data);
  }
}
