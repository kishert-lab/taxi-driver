import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/driver_models.dart';
import '../../../orders/application/order_state_machine.dart';

class ActiveOrderCubit extends Cubit<ActiveOrder?> {
  ActiveOrderCubit(this._stateMachine) : super(null);

  final OrderStateMachine _stateMachine;

  void acceptOffer(OrderOffer offer) {
    emit(
      ActiveOrder(
        id: offer.orderId,
        pickupAddress: offer.pickupAddress,
        destinationAddress: offer.destinationAddress,
        price: offer.price,
        status: DriverOrderStatus.accepted,
        paymentMethod: offer.paymentMethod,
      ),
    );
  }

  void moveTo(DriverOrderStatus next) {
    final current = state;
    if (current == null) {
      return;
    }

    final status = _stateMachine.transition(
      current: current.status,
      next: next,
    );
    emit(current.copyWith(status: status));
  }
}
