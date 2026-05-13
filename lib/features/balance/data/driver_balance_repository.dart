import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/models/driver_models.dart';

class DriverBalanceRepository {
  DriverBalanceRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<BalanceSummary> getBalance() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.driverBalance,
    );
    final data = ApiResponse.data(response.data);
    final availableBalance = _moneyCents(data['available_balance']);
    final pendingBalance = _moneyCents(data['pending_balance']);

    return BalanceSummary(
      currentBalance: availableBalance + pendingBalance,
      availableForWithdrawal: availableBalance,
      periodIncome: 0,
      commissionWithheld: 0,
    );
  }

  Future<List<dynamic>> getTransactions({int limit = 50}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.driverTransactions,
      queryParameters: {'limit': limit},
    );
    return ApiResponse.listField(response.data, 'transactions');
  }

  int _moneyCents(Object? value) {
    if (value is Map<String, dynamic>) {
      return ((value['amount_cents'] as int?) ?? 0) ~/ 100;
    }
    if (value is Map) {
      return ((value['amount_cents'] as int?) ?? 0) ~/ 100;
    }
    return 0;
  }
}
