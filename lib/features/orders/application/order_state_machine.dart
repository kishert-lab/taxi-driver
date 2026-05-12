import '../../../core/errors/app_exception.dart';
import '../../../shared/models/driver_models.dart';

class OrderStateMachine {
  static const Map<DriverOrderStatus, Set<DriverOrderStatus>>
  _allowedTransitions = {
    DriverOrderStatus.offered: {
      DriverOrderStatus.accepted,
      DriverOrderStatus.cancelledByDriver,
    },
    DriverOrderStatus.accepted: {
      DriverOrderStatus.arriving,
      DriverOrderStatus.cancelledByDriver,
      DriverOrderStatus.cancelledByPassenger,
    },
    DriverOrderStatus.arriving: {
      DriverOrderStatus.arrived,
      DriverOrderStatus.cancelledByDriver,
      DriverOrderStatus.cancelledByPassenger,
    },
    DriverOrderStatus.arrived: {
      DriverOrderStatus.waiting,
      DriverOrderStatus.started,
      DriverOrderStatus.noShow,
      DriverOrderStatus.cancelledByDriver,
    },
    DriverOrderStatus.waiting: {
      DriverOrderStatus.started,
      DriverOrderStatus.noShow,
      DriverOrderStatus.cancelledByDriver,
    },
    DriverOrderStatus.started: {
      DriverOrderStatus.completed,
      DriverOrderStatus.cancelledByDispatcher,
    },
    DriverOrderStatus.completed: {},
    DriverOrderStatus.cancelledByDriver: {},
    DriverOrderStatus.cancelledByPassenger: {},
    DriverOrderStatus.cancelledByDispatcher: {},
    DriverOrderStatus.noShow: {},
  };

  DriverOrderStatus transition({
    required DriverOrderStatus current,
    required DriverOrderStatus next,
  }) {
    final allowed = _allowedTransitions[current] ?? const {};
    if (!allowed.contains(next)) {
      throw ValidationException(
        'invalid order status transition from ${current.name} to ${next.name}',
      );
    }

    return next;
  }
}
