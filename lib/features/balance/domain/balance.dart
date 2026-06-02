import '../../orders/domain/driver_order.dart';

class DriverBalance {
  const DriverBalance({
    required this.driverId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.updatedAt,
  });

  final String driverId;
  final Money availableBalance;
  final Money pendingBalance;
  final DateTime? updatedAt;

  factory DriverBalance.fromJson(Map<String, dynamic> json) {
    return DriverBalance(
      driverId: json['driver_id'] as String? ?? '',
      availableBalance: Money.fromCentsJson(
        json['available_balance'] is Map
            ? Map<String, dynamic>.from(json['available_balance'] as Map)
            : null,
      ),
      pendingBalance: Money.fromCentsJson(
        json['pending_balance'] is Map
            ? Map<String, dynamic>.from(json['pending_balance'] as Map)
            : null,
      ),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}

class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.type,
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    required this.currency,
    required this.createdAt,
    this.orderId,
  });

  final String id;
  final String type;
  final int grossAmount;
  final int commissionAmount;
  final int netAmount;
  final String currency;
  final DateTime createdAt;
  final String? orderId;

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      grossAmount: _readAmount(json['gross_amount']),
      commissionAmount: _readAmount(json['commission_amount']),
      netAmount: _readAmount(json['net_amount']),
      currency: _readCurrency(json),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      orderId: json['order_id'] as String?,
    );
  }

  Money get grossMoney => Money(amount: grossAmount, currency: currency);
  Money get commissionMoney =>
      Money(amount: commissionAmount, currency: currency);
  Money get netMoney => Money(amount: netAmount, currency: currency);

  static int _readAmount(Object? value) {
    if (value is Map) {
      final json = Map<String, dynamic>.from(value);
      return (json['amount_cents'] as num?)?.toInt() ??
          (json['amount'] as num?)?.toInt() ??
          0;
    }
    return (value as num?)?.toInt() ?? 0;
  }

  static String _readCurrency(Map<String, dynamic> json) {
    final sources = [
      json['gross_amount'],
      json['commission_amount'],
      json['net_amount'],
    ];
    for (final source in sources) {
      if (source is Map && source['currency'] is String) {
        return source['currency'] as String;
      }
    }
    return json['currency'] as String? ?? 'RUB';
  }
}
