import 'package:equatable/equatable.dart';

enum DriverRole { driver, taxiParkDriver }

enum DriverVerificationStatus {
  newDriver,
  pendingVerification,
  verified,
  rejected,
  blocked,
  inactive,
}

enum DocumentStatus {
  notUploaded,
  uploaded,
  pendingReview,
  approved,
  rejected,
  expired,
}

enum CarClass { economy, comfort, comfortPlus, business, minivan, delivery }

enum CarStatus { pendingReview, approved, rejected, blocked }

enum DriverWorkStatus {
  offline,
  online,
  busy,
  onWayToClient,
  waitingClient,
  inTrip,
  paused,
  blocked,
}

enum DriverOrderStatus {
  offered,
  accepted,
  arriving,
  arrived,
  waiting,
  started,
  completed,
  cancelledByDriver,
  cancelledByPassenger,
  cancelledByDispatcher,
  noShow,
}

enum PaymentMethod { cash, card, corporate, bonus, promoCode }

class DriverProfile extends Equatable {
  const DriverProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.rating,
    required this.status,
    required this.workStatus,
    required this.completedTrips,
    required this.registeredAt,
    this.taxiParkName,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final double rating;
  final DriverVerificationStatus status;
  final DriverWorkStatus workStatus;
  final int completedTrips;
  final DateTime registeredAt;
  final String? taxiParkName;

  bool get canWork =>
      status == DriverVerificationStatus.verified &&
      workStatus != DriverWorkStatus.blocked;

  @override
  List<Object?> get props => [
    id,
    fullName,
    phone,
    email,
    city,
    rating,
    status,
    workStatus,
    completedTrips,
    registeredAt,
    taxiParkName,
  ];
}

class DriverDocument extends Equatable {
  const DriverDocument({
    required this.id,
    required this.type,
    required this.status,
    required this.required,
    this.rejectionReason,
    this.expiresAt,
  });

  final String id;
  final String type;
  final DocumentStatus status;
  final bool required;
  final String? rejectionReason;
  final DateTime? expiresAt;

  bool get isApproved => status == DocumentStatus.approved;

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    required,
    rejectionReason,
    expiresAt,
  ];
}

class DriverCar extends Equatable {
  const DriverCar({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.color,
    required this.carClass,
    required this.status,
  });

  final String id;
  final String brand;
  final String model;
  final int year;
  final String plateNumber;
  final String color;
  final CarClass carClass;
  final CarStatus status;

  bool get isApproved => status == CarStatus.approved;

  @override
  List<Object?> get props => [
    id,
    brand,
    model,
    year,
    plateNumber,
    color,
    carClass,
    status,
  ];
}

class DriverLocation extends Equatable {
  const DriverLocation({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bearing,
    required this.accuracy,
    required this.status,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double speed;
  final double bearing;
  final double accuracy;
  final DriverWorkStatus status;
  final DateTime timestamp;

  Map<String, dynamic> toJson(String driverId) {
    return {
      'driver_id': driverId,
      'lat': latitude,
      'lon': longitude,
      'speed': speed,
      'bearing': bearing,
      'accuracy': accuracy,
      'status': status.name,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    speed,
    bearing,
    accuracy,
    status,
    timestamp,
  ];
}

class OrderOffer extends Equatable {
  const OrderOffer({
    required this.orderId,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.price,
    required this.distanceToPickupMeters,
    required this.expiresInSeconds,
    required this.paymentMethod,
  });

  final String orderId;
  final String pickupAddress;
  final String? destinationAddress;
  final int price;
  final int distanceToPickupMeters;
  final int expiresInSeconds;
  final PaymentMethod paymentMethod;

  @override
  List<Object?> get props => [
    orderId,
    pickupAddress,
    destinationAddress,
    price,
    distanceToPickupMeters,
    expiresInSeconds,
    paymentMethod,
  ];
}

class ActiveOrder extends Equatable {
  const ActiveOrder({
    required this.id,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.price,
    required this.status,
    required this.paymentMethod,
  });

  final String id;
  final String pickupAddress;
  final String? destinationAddress;
  final int price;
  final DriverOrderStatus status;
  final PaymentMethod paymentMethod;

  ActiveOrder copyWith({DriverOrderStatus? status}) {
    return ActiveOrder(
      id: id,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      price: price,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pickupAddress,
    destinationAddress,
    price,
    status,
    paymentMethod,
  ];
}

class BalanceSummary extends Equatable {
  const BalanceSummary({
    required this.currentBalance,
    required this.availableForWithdrawal,
    required this.periodIncome,
    required this.commissionWithheld,
  });

  final int currentBalance;
  final int availableForWithdrawal;
  final int periodIncome;
  final int commissionWithheld;

  @override
  List<Object?> get props => [
    currentBalance,
    availableForWithdrawal,
    periodIncome,
    commissionWithheld,
  ];
}
