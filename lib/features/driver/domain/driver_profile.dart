enum DriverStatus { offline, online, busy, paused, blocked, unknown }

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
    );
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
      DriverStatus.busy => 'Занят',
      DriverStatus.paused => 'Пауза',
      DriverStatus.blocked => 'Заблокирован',
      DriverStatus.unknown => 'Неизвестно',
    };
  }

  bool get canSendLocation {
    return this == DriverStatus.online || this == DriverStatus.busy;
  }
}
