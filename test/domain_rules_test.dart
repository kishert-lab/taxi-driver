import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_driver_app/features/balance/application/commission_calculator.dart';
import 'package:taxi_driver_app/features/orders/application/order_state_machine.dart';
import 'package:taxi_driver_app/features/shift/application/driver_access_policy.dart';
import 'package:taxi_driver_app/shared/models/driver_models.dart';

void main() {
  test('driver cannot start shift without approved required documents', () {
    final policy = DriverAccessPolicy();
    final result = policy.canStartShift(
      profile: DriverProfile(
        id: 'driver-id',
        fullName: 'Driver',
        phone: '+79000000000',
        email: 'driver@example.com',
        city: 'Perm',
        rating: 5,
        status: DriverVerificationStatus.verified,
        workStatus: DriverWorkStatus.offline,
        completedTrips: 0,
        registeredAt: DateTime.utc(2026),
      ),
      documents: const [
        DriverDocument(
          id: 'passport',
          type: 'passport',
          status: DocumentStatus.pendingReview,
          required: true,
        ),
      ],
      selectedCar: const DriverCar(
        id: 'car-id',
        brand: 'Kia',
        model: 'Rio',
        year: 2022,
        plateNumber: 'A123BC159',
        color: 'White',
        carClass: CarClass.economy,
        status: CarStatus.approved,
      ),
      locationEnabled: true,
      hasLocationPermission: true,
      balance: 0,
      minimumBalance: 0,
    );

    expect(result.allowed, isFalse);
  });

  test('order state machine rejects invalid transition', () {
    final stateMachine = OrderStateMachine();

    expect(
      () => stateMachine.transition(
        current: DriverOrderStatus.offered,
        next: DriverOrderStatus.completed,
      ),
      throwsException,
    );
  });

  test('platform commission is one percent', () {
    const calculator = CommissionCalculator(platformRate: 0.01);

    final breakdown = calculator.calculate(500);

    expect(breakdown.commissionAmount, 5);
    expect(breakdown.driverIncome, 495);
  });
}
