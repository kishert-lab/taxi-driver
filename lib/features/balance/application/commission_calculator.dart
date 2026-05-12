class CommissionCalculator {
  const CommissionCalculator({required this.platformRate});

  final double platformRate;

  CommissionBreakdown calculate(int orderAmount) {
    final commission = (orderAmount * platformRate).round();
    return CommissionBreakdown(
      orderAmount: orderAmount,
      commissionPercent: platformRate * 100,
      commissionAmount: commission,
      driverIncome: orderAmount - commission,
    );
  }
}

class CommissionBreakdown {
  const CommissionBreakdown({
    required this.orderAmount,
    required this.commissionPercent,
    required this.commissionAmount,
    required this.driverIncome,
  });

  final int orderAmount;
  final double commissionPercent;
  final int commissionAmount;
  final int driverIncome;
}
