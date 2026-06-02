enum DriverStatus { offline, online, busy, paused, blocked, unknown }

enum VerificationStatus {
  draft,
  pendingVerification,
  verified,
  rejected,
  blocked,
  archived,
  unknown,
}

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.userId,
    required this.phone,
    required this.name,
    required this.status,
    required this.rating,
    required this.ratingsCount,
    required this.isVerified,
    this.photoUrl,
    this.licenseNumber,
    this.verificationStatus,
    this.taxiParkId,
    this.taxiParkIsActive,
    this.hasNoTaxiWorkRestrictions,
    this.federalLaw580Compliant,
    this.regionalRequirementsCompliant,
    this.medicalCheckPassed,
    this.pretripControlRequired,
    this.pretripControlPassed,
    this.noTransportBan,
    this.car,
    this.cars = const [],
  });

  final String id;
  final String userId;
  final String phone;
  final String name;
  final String? photoUrl;
  final DriverStatus status;
  final double rating;
  final int ratingsCount;
  final String? licenseNumber;
  final bool isVerified;
  final VerificationStatus? verificationStatus;
  final String? taxiParkId;
  final bool? taxiParkIsActive;
  final bool? hasNoTaxiWorkRestrictions;
  final bool? federalLaw580Compliant;
  final bool? regionalRequirementsCompliant;
  final bool? medicalCheckPassed;
  final bool? pretripControlRequired;
  final bool? pretripControlPassed;
  final bool? noTransportBan;
  final DriverCar? car;
  final List<DriverCar> cars;

  List<DriverCar> get attachedCars {
    if (cars.isNotEmpty) {
      return cars;
    }
    final car = this.car;
    return car == null ? const [] : [car];
  }

  DriverCar? get primaryCar {
    for (final car in attachedCars) {
      if (car.isActive) {
        return car;
      }
    }
    return attachedCars.isEmpty ? null : attachedCars.first;
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String? ?? 'Водитель',
      photoUrl: json['photo_url'] as String?,
      status: DriverStatusX.fromBackend(json['status'] as String?),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingsCount: (json['ratings_count'] as num?)?.toInt() ?? 0,
      licenseNumber: json['license_number'] as String?,
      isVerified: json['is_verified'] == true,
      verificationStatus: VerificationStatusX.fromBackendOrNull(
        json['verification_status'] as String?,
      ),
      taxiParkId: json['taxi_park_id'] as String?,
      taxiParkIsActive:
          json['taxi_park_is_active'] as bool? ??
          _object(json['taxi_park_settings'])?['is_active'] as bool?,
      hasNoTaxiWorkRestrictions: json['has_no_taxi_work_restrictions'] as bool?,
      federalLaw580Compliant: json['federal_law_580_compliant'] as bool?,
      regionalRequirementsCompliant:
          json['regional_requirements_compliant'] as bool?,
      medicalCheckPassed: json['medical_check_passed'] as bool?,
      pretripControlRequired: json['pretrip_control_required'] as bool?,
      pretripControlPassed: json['pretrip_control_passed'] as bool?,
      noTransportBan: json['no_transport_ban'] as bool?,
      car: DriverCar.fromNullableJson(
        _object(json['car']) ??
            _object(json['vehicle']) ??
            _object(json['active_car']),
      ),
      cars: _carsFromJson(json),
    );
  }

  DriverProfile copyWith({DriverStatus? status, List<DriverCar>? cars}) {
    return DriverProfile(
      id: id,
      userId: userId,
      phone: phone,
      name: name,
      status: status ?? this.status,
      rating: rating,
      ratingsCount: ratingsCount,
      isVerified: isVerified,
      photoUrl: photoUrl,
      licenseNumber: licenseNumber,
      verificationStatus: verificationStatus,
      taxiParkId: taxiParkId,
      taxiParkIsActive: taxiParkIsActive,
      hasNoTaxiWorkRestrictions: hasNoTaxiWorkRestrictions,
      federalLaw580Compliant: federalLaw580Compliant,
      regionalRequirementsCompliant: regionalRequirementsCompliant,
      medicalCheckPassed: medicalCheckPassed,
      pretripControlRequired: pretripControlRequired,
      pretripControlPassed: pretripControlPassed,
      noTransportBan: noTransportBan,
      car: car,
      cars: cars ?? this.cars,
    );
  }

  List<String> onlineBlockReasons({DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final reasons = <String>[];

    if (taxiParkId == null || taxiParkId!.isEmpty) {
      reasons.add('Водитель не привязан к таксопарку.');
    }
    if (verificationStatus != VerificationStatus.verified || !isVerified) {
      reasons.add('Водитель не проверен таксопарком.');
    }
    if (status == DriverStatus.blocked) {
      reasons.add('Водитель заблокирован.');
    }
    if (verificationStatus == VerificationStatus.blocked ||
        verificationStatus == VerificationStatus.rejected ||
        verificationStatus == VerificationStatus.archived) {
      reasons.add('Проверка водителя: ${verificationStatus!.label}.');
    }
    if (taxiParkIsActive == false) {
      reasons.add('Таксопарк не активен.');
    }
    if (hasNoTaxiWorkRestrictions == false) {
      reasons.add('Есть ограничения на работу в такси.');
    }
    if (federalLaw580Compliant == false) {
      reasons.add('Не подтверждено соответствие 580-ФЗ.');
    }
    if (regionalRequirementsCompliant == false) {
      reasons.add('Не выполнены региональные требования.');
    }
    if (medicalCheckPassed == false) {
      reasons.add('Не пройден медицинский контроль.');
    }
    if (pretripControlRequired == true && pretripControlPassed != true) {
      reasons.add('Не пройден предрейсовый контроль.');
    }
    if (noTransportBan == false) {
      reasons.add('Есть запрет на управление транспортом.');
    }

    final cars = attachedCars;
    if (cars.isEmpty) {
      reasons.add('У водителя нет привязанной машины.');
      return reasons;
    }

    final readyCars = cars.where((car) => car.canGoOnline(today)).toList();
    if (readyCars.isEmpty) {
      reasons.add('Нет автомобиля, готового к выходу на линию.');
      for (final car in cars) {
        reasons.addAll(
          car.onlineBlockReasons(today).map((reason) => '${car.title}: $reason'),
        );
      }
    }

    return reasons;
  }

  static List<DriverCar> _carsFromJson(Map<String, dynamic> json) {
    final values =
        _list(json['cars']) ??
        _list(json['vehicles']) ??
        _list(json['active_cars']) ??
        const [];
    return values
        .whereType<Map>()
        .map((item) => DriverCar.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static List<dynamic>? _list(Object? value) => value is List ? value : null;

  static Map<String, dynamic>? _object(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}

class DriverCar {
  const DriverCar({
    required this.id,
    required this.brand,
    required this.model,
    required this.plateNumber,
    required this.verificationStatus,
    required this.isActive,
    this.year,
    this.color,
    this.carClass,
    this.osagoExpiresAt,
    this.permitExpiresAt,
  });

  final String id;
  final String brand;
  final String model;
  final int? year;
  final String plateNumber;
  final String? color;
  final String? carClass;
  final VerificationStatus verificationStatus;
  final bool isActive;
  final DateTime? osagoExpiresAt;
  final DateTime? permitExpiresAt;

  String get title {
    final parts = [brand, model].where((part) => part.trim().isNotEmpty);
    final value = parts.join(' ');
    return value.isEmpty ? 'Не указан' : value;
  }

  factory DriverCar.fromJson(Map<String, dynamic> json) {
    return DriverCar(
      id: json['id'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: (json['year'] as num?)?.toInt(),
      plateNumber: json['plate_number'] as String? ?? '',
      color: json['color'] as String?,
      carClass: json['car_class'] as String?,
      verificationStatus: VerificationStatusX.fromBackend(
        json['verification_status'] as String?,
      ),
      isActive: json['is_active'] == true,
      osagoExpiresAt: _date(json['osago_expires_at']),
      permitExpiresAt: _date(json['permit_expires_at']),
    );
  }

  static DriverCar? fromNullableJson(Map<String, dynamic>? json) {
    return json == null ? null : DriverCar.fromJson(json);
  }

  bool canGoOnline(DateTime today) => onlineBlockReasons(today).isEmpty;

  List<String> onlineBlockReasons(DateTime today) {
    final reasons = <String>[];
    if (verificationStatus != VerificationStatus.verified) {
      reasons.add('машина не проверена (${verificationStatus.label}).');
    }
    if (!isActive) {
      reasons.add('машина не активна.');
    }
    if (osagoExpiresAt == null) {
      reasons.add('не указан срок действия ОСАГО.');
    } else if (osagoExpiresAt!.isBefore(today)) {
      reasons.add('ОСАГО просрочено.');
    }
    if (permitExpiresAt == null) {
      reasons.add('не указан срок действия разрешения такси.');
    } else if (permitExpiresAt!.isBefore(today)) {
      reasons.add('разрешение такси просрочено.');
    }
    return reasons;
  }

  static DateTime? _date(Object? value) {
    final parsed = DateTime.tryParse(value as String? ?? '');
    if (parsed == null) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}

extension DriverStatusX on DriverStatus {
  static DriverStatus fromBackend(String? value) {
    return switch (value) {
      'offline' => DriverStatus.offline,
      'online' => DriverStatus.online,
      'busy' => DriverStatus.busy,
      'paused' => DriverStatus.paused,
      'blocked' => DriverStatus.blocked,
      _ => DriverStatus.unknown,
    };
  }

  String get label {
    return switch (this) {
      DriverStatus.offline => 'Не на линии',
      DriverStatus.online => 'На линии',
      DriverStatus.busy => 'В заказе',
      DriverStatus.paused => 'Пауза',
      DriverStatus.blocked => 'Заблокирован',
      DriverStatus.unknown => 'Неизвестно',
    };
  }

  bool get canSendLocation => this == DriverStatus.online || this == DriverStatus.busy;
}

extension VerificationStatusX on VerificationStatus {
  static VerificationStatus fromBackend(String? value) {
    return fromBackendOrNull(value) ?? VerificationStatus.unknown;
  }

  static VerificationStatus? fromBackendOrNull(String? value) {
    return switch (value) {
      'draft' => VerificationStatus.draft,
      'pending_verification' => VerificationStatus.pendingVerification,
      'verified' => VerificationStatus.verified,
      'rejected' => VerificationStatus.rejected,
      'blocked' => VerificationStatus.blocked,
      'archived' => VerificationStatus.archived,
      null => null,
      _ => VerificationStatus.unknown,
    };
  }

  String get label {
    return switch (this) {
      VerificationStatus.verified => 'Проверен',
      VerificationStatus.pendingVerification => 'На проверке',
      VerificationStatus.draft => 'Черновик',
      VerificationStatus.rejected => 'Отклонен',
      VerificationStatus.blocked => 'Заблокирован',
      VerificationStatus.archived => 'Архив',
      VerificationStatus.unknown => 'Неизвестно',
    };
  }
}
