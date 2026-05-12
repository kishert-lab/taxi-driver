import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/driver_models.dart';

class OrdersCubit extends Cubit<OrderOffer?> {
  OrdersCubit() : super(null);

  void showOffer(OrderOffer offer) {
    emit(offer);
  }

  void clearOffer() {
    emit(null);
  }
}
