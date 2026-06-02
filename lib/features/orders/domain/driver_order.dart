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
    final locationJson =
        json['location'] as Map? ?? json['coordinates'] as Map? ?? const {};
    return OrderPoint(
      address: json['address'] as String? ?? json['name'] as String? ?? '',
      location: Coordinates.fromJson(Map<String, dynamic>.from(locationJson)),
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

  factory Money.fromCentsJson(Map<String, dynamic>? json) {
    return Money(
      amount: (json?['amount_cents'] as num?)?.toInt() ?? 0,
      currency: json?['currency'] as String? ?? 'RUB',
    );
  }

  factory Money.fromValue(Object? value) {
    if (value is Map) {
      return Money.fromJson(Map<String, dynamic>.from(value));
    }
    return Money(amount: (value as num?)?.toInt() ?? 0, currency: 'RUB');
  }

  double get units => amount / 100;

  String get formatted {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: currency == 'RUB' ? '₽' : '$currency ',
      decimalDigits: 2,
    );
    return formatter.format(units);
  }
}

class PassengerBrief {
  const PassengerBrief({
    required this.id,
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.rating,
    required this.ratingsCount,
  });

  final String id;
  final String name;
  final String phone;
  final String photoUrl;
  final double rating;
  final int ratingsCount;

  factory PassengerBrief.fromJson(Map<String, dynamic> json) {
    return PassengerBrief(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Пассажир',
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingsCount: (json['ratings_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class OrderTimelineItem {
  const OrderTimelineItem({required this.status, required this.recordedAt});

  final String status;
  final DateTime? recordedAt;

  factory OrderTimelineItem.fromJson(Map<String, dynamic> json) {
    return OrderTimelineItem(
      status: json['status'] as String? ?? json['type'] as String? ?? '',
      recordedAt: _parseDate(
        json['recorded_at'] as String? ??
            json['created_at'] as String? ??
            json['occurred_at'] as String? ??
            json['at'] as String?,
      ),
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
    required this.timeline,
    required this.version,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  final String orderId;
  final PassengerBrief passenger;
  final OrderPoint pickupPoint;
  final OrderPoint destinationPoint;
  final String status;
  final Money price;
  final String? comment;
  final List<String> allowedActions;
  final List<OrderTimelineItem> timeline;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DriverOrder.fromJson(Map<String, dynamic> json) {
    final timeline = (json['timeline'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => OrderTimelineItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    return DriverOrder(
      orderId: json['order_id'] as String? ?? json['id'] as String? ?? '',
      passenger: PassengerBrief.fromJson(
        Map<String, dynamic>.from(json['passenger'] as Map? ?? const {}),
      ),
      pickupPoint: OrderPoint.fromJson(
        Map<String, dynamic>.from(
          json['pickup_point'] as Map? ?? json['pickup'] as Map? ?? const {},
        ),
      ),
      destinationPoint: OrderPoint.fromJson(
        Map<String, dynamic>.from(
          json['destination_point'] as Map? ??
              json['destination'] as Map? ??
              const {},
        ),
      ),
      status: json['status'] as String? ?? '',
      price: Money.fromValue(json['price'] ?? json['estimated_price']),
      comment: json['comment'] as String?,
      allowedActions: (json['allowed_actions'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      timeline: timeline,
      version: (json['version'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at'] as String?),
      updatedAt: _parseDate(
        json['updated_at'] as String? ??
            json['completed_at'] as String? ??
            json['cancelled_at'] as String?,
      ),
    );
  }

  bool get isInProgress => status == 'in_progress';

  bool get isTerminal {
    return switch (status) {
      'completed' ||
      'cancelled' ||
      'failed' ||
      'cancelled_by_driver' ||
      'cancelled_by_passenger' ||
      'cancelled_by_dispatcher' => true,
      _ => false,
    };
  }

  DateTime? get displayDate {
    if (updatedAt != null) {
      return updatedAt;
    }
    if (createdAt != null) {
      return createdAt;
    }
    for (final item in timeline.reversed) {
      if (item.recordedAt != null) {
        return item.recordedAt;
      }
    }
    return null;
  }

  String get statusLabel {
    return switch (status) {
      'offered' => 'Новый заказ',
      'driver_assigned' || 'arriving' => 'Еду к пассажиру',
      'arrived' => 'Ожидание пассажира',
      'in_progress' => 'Поездка началась',
      'completed' => 'Поездка завершена',
      'cancelled' => 'Заказ отменён',
      'failed' => 'Заказ не выполнен',
      'cancelled_by_driver' => 'Отменён водителем',
      'cancelled_by_passenger' => 'Отменён пассажиром',
      'cancelled_by_dispatcher' => 'Отменён диспетчером',
      _ => status,
    };
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
          _parseDate(payload['occurred_at'] as String?) ??
          DateTime.now().toUtc(),
      expiresAt: _parseDate(payload['expires_at'] as String?),
      distanceMeters: (payload['distance_meters'] as num?)?.toInt(),
    );
  }
}

class DriverRoutePoint {
  const DriverRoutePoint({
    required this.id,
    required this.location,
    this.recordedAt,
    this.heading,
    this.speedMetersPerSecond,
    this.accuracyMeters,
  });

  final String id;
  final Coordinates location;
  final DateTime? recordedAt;
  final double? heading;
  final double? speedMetersPerSecond;
  final double? accuracyMeters;

  factory DriverRoutePoint.fromJson(Map<String, dynamic> json) {
    final locationJson =
        json['location'] as Map? ?? json['coordinates'] as Map? ?? json;
    return DriverRoutePoint(
      id: json['id'] as String? ?? '',
      location: Coordinates.fromJson(Map<String, dynamic>.from(locationJson)),
      recordedAt: _parseDate(
        json['recorded_at'] as String? ?? json['created_at'] as String?,
      ),
      heading: (json['heading'] as num?)?.toDouble(),
      speedMetersPerSecond: (json['speed_mps'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
    );
  }
}

class DriverRoute {
  const DriverRoute({required this.orderId, required this.points});

  final String orderId;
  final List<DriverRoutePoint> points;

  factory DriverRoute.fromJson(Map<String, dynamic> json) {
    final values =
        json['points'] as List? ??
        json['locations'] as List? ??
        json['route'] as List? ??
        const [];
    return DriverRoute(
      orderId: json['order_id'] as String? ?? json['id'] as String? ?? '',
      points: values
          .whereType<Map>()
          .map(
            (item) =>
                DriverRoutePoint.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
