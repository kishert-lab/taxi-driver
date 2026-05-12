import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/driver_models.dart';

class DriverProfileCubit extends Cubit<DriverProfile?> {
  DriverProfileCubit()
    : super(
        DriverProfile(
          id: 'local-driver',
          fullName: 'Водитель',
          phone: '+7 900 000-00-00',
          email: 'driver@example.com',
          city: 'Пермь',
          rating: 5,
          status: DriverVerificationStatus.pendingVerification,
          workStatus: DriverWorkStatus.offline,
          completedTrips: 0,
          registeredAt: DateTime.now().toUtc(),
        ),
      );

  void markVerifiedForDemo() {
    final current = state;
    if (current == null) {
      return;
    }

    emit(
      DriverProfile(
        id: current.id,
        fullName: current.fullName,
        phone: current.phone,
        email: current.email,
        city: current.city,
        rating: current.rating,
        status: DriverVerificationStatus.verified,
        workStatus: current.workStatus,
        completedTrips: current.completedTrips,
        registeredAt: current.registeredAt,
        taxiParkName: current.taxiParkName,
      ),
    );
  }
}
