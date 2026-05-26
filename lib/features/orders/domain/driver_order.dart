import 'package:intl/intl.dart';

class Coordinates {
  const Coordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class OrderPoint {
  const OrderPoint({required this.address, required this.location});

  final String address;
  final Coordinates location;

  factory OrderPoint.fromJson(Map<String, dynamic> json) {
    return OrderPoint(
      address: json['address'] as String? ?? '',
      location: Coordinates.fromJson(
        Map<String, dynamic>.from(json['location'] as Map? ?? const {}),
      ),
    );
  }
}

class Money {
  const Money({required this.amount, required this.currency});

  final int amount;
  final String currency;

  factory Money.fromJson(Map<String, dynamic>? json) {
    return Money(
      amount: (json?['amount'] as num?)?.toInt() ?? 0,
      currency: json?['currency'] as String? ?? 'RUB',
    );
  }

  String get formatted {
    final value = amount >= 10000 ? amount / 100 : amount.toDouble();
    return '${NumberFormat.decimalPattern('ru_RU').format(value)} ₽';
  }
}

class PassengerBrief {
  const PassengerBrief({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
  });

  final String id;
  final String name;
  final String phone;
  final double rating;

  factory PassengerBrief.fromJson(Map<String, dynamic> json) {
    return PassengerBrief(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Пассажир',
      phone: json['phone'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DriverOrder {
  const DriverOrder({
    required this.orderId,
    required this.passenger,
    required this.pickupPoint,
    required this.destinationPoint,
    required this.status,
    required this.price,
    required this.allowedActions,
    required this.version,
    this.comment,
  });

  final String orderId;
  final PassengerBrief passenger;
  final OrderPoint pickupPoint;
  final OrderPoint destinationPoint;
  final String status;
  final Money price;
  final String? comment;
  final List<String> allowedActions;
  final int version;

  factory DriverOrder.fromJson(Map<String, dynamic> json) {
    return DriverOrder(
      orderId: json['order_id'] as String? ?? json['id'] as String? ?? '',
      passenger: PassengerBrief.fromJson(
        Map<String, dynamic>.from(json['passenger'] as Map? ?? const {}),
      ),
      pickupPoint: OrderPoint.fromJson(
        Map<String, dynamic>.from(json['pickup_point'] as Map? ?? const {}),
      ),
      destinationPoint: OrderPoint.fromJson(
        Map<String, dynamic>.from(
          json['destination_point'] as Map? ?? const {},
        ),
      ),
      status: json['status'] as String? ?? '',
      price: Money.fromJson(
        json['price'] is Map
            ? Map<String, dynamic>.from(json['price'] as Map)
            : null,
      ),
      comment: json['comment'] as String?,
      allowedActions: (json['allowed_actions'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }
}

class OrderOffer {
  const OrderOffer({
    required this.order,
    required this.occurredAt,
    this.expiresAt,
    this.distanceMeters,
  });

  final DriverOrder order;
  final DateTime occurredAt;
  final DateTime? expiresAt;
  final int? distanceMeters;

  factory OrderOffer.fromPayload(Map<String, dynamic> payload) {
    final orderJson = payload['order'] is Map ? payload['order'] : payload;
    return OrderOffer(
      order: DriverOrder.fromJson(Map<String, dynamic>.from(orderJson as Map)),
      occurredAt:
          DateTime.tryParse(payload['occurred_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      expiresAt: DateTime.tryParse(payload['expires_at'] as String? ?? ''),
      distanceMeters: (payload['distance_meters'] as num?)?.toInt(),
    );
  }
}
