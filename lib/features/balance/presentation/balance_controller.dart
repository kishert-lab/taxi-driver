import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/utils/async_state.dart';
import '../data/balance_repository.dart';
import '../domain/balance.dart';

class BalanceViewData {
  const BalanceViewData({required this.balance, required this.transactions});

  final DriverBalance? balance;
  final List<FinancialTransaction> transactions;
}

final balanceProvider =
    StateNotifierProvider<BalanceController, Loadable<BalanceViewData>>((ref) {
      return BalanceController(ref.watch(balanceRepositoryProvider));
    });

class BalanceController extends StateNotifier<Loadable<BalanceViewData>> {
  BalanceController(this._repository)
    : super(
        const Loadable.idle(BalanceViewData(balance: null, transactions: [])),
      );

  final BalanceRepository _repository;

  Future<void> load() async {
    state = Loadable.loading(state.value);
    try {
      final balance = await _repository.balance();
      final transactions = await _repository.transactions();
      state = Loadable.idle(
        BalanceViewData(balance: balance, transactions: transactions),
      );
    } on ApiException catch (error) {
      state = Loadable(
        isLoading: false,
        value: state.value,
        errorMessage: error.userMessage,
      );
    }
  }
}
