import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/balance.dart';

abstract class BalanceRepository {
  Future<DriverBalance> balance();
  Future<List<FinancialTransaction>> transactions({int limit = 50});
}

class TaxiBalanceRepository implements BalanceRepository {
  TaxiBalanceRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<DriverBalance> balance() {
    return _apiClient.get(
      '/driver/balance',
      parser: (json) => DriverBalance.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
  }

  @override
  Future<List<FinancialTransaction>> transactions({int limit = 50}) {
    return _apiClient.get(
      '/driver/transactions',
      queryParameters: {'limit': limit},
      parser: (json) {
        final payload = Map<String, dynamic>.from(json as Map? ?? const {});
        final items = payload['transactions'] as List? ?? const [];
        return items
            .whereType<Map>()
            .map(
              (item) => FinancialTransaction.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false);
      },
    );
  }
}

final balanceRepositoryProvider = Provider<BalanceRepository>(
  (ref) => TaxiBalanceRepository(ref.watch(apiClientProvider)),
);
