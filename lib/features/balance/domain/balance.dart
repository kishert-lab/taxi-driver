import '../../orders/domain/driver_order.dart';

class DriverBalance {
  const DriverBalance({
    required this.availableBalance,
    required this.pendingBalance,
  });

  final Money availableBalance;
  final Money pendingBalance;

  factory DriverBalance.fromJson(Map<String, dynamic> json) {
    return DriverBalance(
      availableBalance: _moneyCents(json['available_balance']),
      pendingBalance: _moneyCents(json['pending_balance']),
    );
  }

  static Money _moneyCents(Object? value) {
    final json = value is Map ? Map<String, dynamic>.from(value) : const {};
    return Money(
      amount: (json['amount_cents'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'RUB',
    );
  }
}

class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.description,
  });

  final String id;
  final Money amount;
  final String type;
  final String? description;
  final DateTime createdAt;

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] as String? ?? '',
      amount: DriverBalance._moneyCents(json['amount']),
      type: json['type'] as String? ?? '',
      description: json['description'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
