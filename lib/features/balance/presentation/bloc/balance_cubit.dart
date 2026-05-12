import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/driver_models.dart';
import '../../application/commission_calculator.dart';

class BalanceState extends Equatable {
  const BalanceState({required this.summary, this.lastCommission});

  final BalanceSummary summary;
  final CommissionBreakdown? lastCommission;

  @override
  List<Object?> get props => [summary, lastCommission];
}

class BalanceCubit extends Cubit<BalanceState> {
  BalanceCubit(this._commissionCalculator)
    : super(
        const BalanceState(
          summary: BalanceSummary(
            currentBalance: 0,
            availableForWithdrawal: 0,
            periodIncome: 0,
            commissionWithheld: 0,
          ),
        ),
      );

  final CommissionCalculator _commissionCalculator;

  void applyCompletedOrder(int orderAmount) {
    final commission = _commissionCalculator.calculate(orderAmount);
    final current = state.summary;
    emit(
      BalanceState(
        summary: BalanceSummary(
          currentBalance: current.currentBalance + commission.driverIncome,
          availableForWithdrawal:
              current.availableForWithdrawal + commission.driverIncome,
          periodIncome: current.periodIncome + orderAmount,
          commissionWithheld:
              current.commissionWithheld + commission.commissionAmount,
        ),
        lastCommission: commission,
      ),
    );
  }
}
