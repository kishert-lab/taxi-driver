import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/driver_models.dart';
import '../../application/driver_access_policy.dart';

class ShiftState extends Equatable {
  const ShiftState({required this.status, this.startedAt, this.message});

  final DriverWorkStatus status;
  final DateTime? startedAt;
  final String? message;

  @override
  List<Object?> get props => [status, startedAt, message];
}

class ShiftCubit extends Cubit<ShiftState> {
  ShiftCubit({required DriverAccessPolicy accessPolicy})
    : _accessPolicy = accessPolicy,
      super(const ShiftState(status: DriverWorkStatus.offline));

  final DriverAccessPolicy _accessPolicy;

  void startShift({
    required DriverProfile? profile,
    required List<DriverDocument> documents,
    required DriverCar? selectedCar,
    required bool locationEnabled,
    required bool hasLocationPermission,
    required int balance,
    required int minimumBalance,
  }) {
    final result = _accessPolicy.canStartShift(
      profile: profile,
      documents: documents,
      selectedCar: selectedCar,
      locationEnabled: locationEnabled,
      hasLocationPermission: hasLocationPermission,
      balance: balance,
      minimumBalance: minimumBalance,
    );

    if (!result.allowed) {
      emit(
        ShiftState(status: DriverWorkStatus.offline, message: result.reason),
      );
      return;
    }

    emit(
      ShiftState(
        status: DriverWorkStatus.online,
        startedAt: DateTime.now().toUtc(),
      ),
    );
  }

  void finishShift() {
    emit(const ShiftState(status: DriverWorkStatus.offline));
  }
}
