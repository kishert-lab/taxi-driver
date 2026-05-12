import '../../../shared/models/driver_models.dart';

class DriverAccessPolicy {
  DriverLineAccessResult canStartShift({
    required DriverProfile? profile,
    required List<DriverDocument> documents,
    required DriverCar? selectedCar,
    required bool locationEnabled,
    required bool hasLocationPermission,
    required int balance,
    required int minimumBalance,
  }) {
    if (profile == null ||
        profile.status != DriverVerificationStatus.verified) {
      return const DriverLineAccessResult.denied(
        'Невозможно выйти на линию: водитель не подтверждён',
      );
    }
    if (profile.workStatus == DriverWorkStatus.blocked) {
      return const DriverLineAccessResult.denied(
        'Невозможно выйти на линию: водитель заблокирован',
      );
    }
    if (selectedCar == null || selectedCar.status != CarStatus.approved) {
      return const DriverLineAccessResult.denied(
        'Невозможно выйти на линию: автомобиль не подтверждён',
      );
    }
    final hasRejectedRequiredDocument = documents.any(
      (document) =>
          document.required && document.status != DocumentStatus.approved,
    );
    if (hasRejectedRequiredDocument) {
      return const DriverLineAccessResult.denied(
        'Невозможно выйти на линию: не подтверждены документы',
      );
    }
    if (!locationEnabled) {
      return const DriverLineAccessResult.denied('Геолокация отключена');
    }
    if (!hasLocationPermission) {
      return const DriverLineAccessResult.denied(
        'Разрешите доступ к геолокации',
      );
    }
    if (balance < minimumBalance) {
      return const DriverLineAccessResult.denied(
        'Недостаточно средств на балансе',
      );
    }

    return const DriverLineAccessResult.allowed();
  }
}

class DriverLineAccessResult {
  const DriverLineAccessResult._({required this.allowed, this.reason});

  const DriverLineAccessResult.allowed() : this._(allowed: true);

  const DriverLineAccessResult.denied(String reason)
    : this._(allowed: false, reason: reason);

  final bool allowed;
  final String? reason;
}
