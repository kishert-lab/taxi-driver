import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/driver_models.dart';

class CarsCubit extends Cubit<List<DriverCar>> {
  CarsCubit()
    : super(const [
        DriverCar(
          id: 'demo-car',
          brand: 'Kia',
          model: 'Rio',
          year: 2022,
          plateNumber: 'А123ВС159',
          color: 'Белый',
          carClass: CarClass.economy,
          status: CarStatus.pendingReview,
        ),
      ]);

  DriverCar? get selectedCar => state.isEmpty ? null : state.first;

  void approveSelectedForDemo() {
    final car = selectedCar;
    if (car == null) {
      return;
    }

    emit([
      DriverCar(
        id: car.id,
        brand: car.brand,
        model: car.model,
        year: car.year,
        plateNumber: car.plateNumber,
        color: car.color,
        carClass: car.carClass,
        status: CarStatus.approved,
      ),
    ]);
  }
}
