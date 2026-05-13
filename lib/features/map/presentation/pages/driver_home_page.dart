import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/navigation/external_navigation_service.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/models/driver_models.dart';
import '../../../../shared/widgets/driver_section.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../active_order/presentation/bloc/active_order_cubit.dart';
import '../../../balance/presentation/bloc/balance_cubit.dart';
import '../../../cars/presentation/bloc/cars_cubit.dart';
import '../../../documents/presentation/bloc/documents_cubit.dart';
import '../../../driver_profile/presentation/bloc/driver_profile_cubit.dart';
import '../../../orders/presentation/bloc/orders_cubit.dart';
import '../../../shift/presentation/bloc/shift_cubit.dart';

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Водитель'),
        actions: [
          IconButton(
            tooltip: 'Уведомления',
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Настройки',
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _MapPanel(),
            SizedBox(height: 12),
            _ShiftPanel(),
            SizedBox(height: 12),
            _OrderOfferPanel(),
            SizedBox(height: 12),
            _ActiveOrderPanel(),
            SizedBox(height: 12),
            _DriverReadinessPanel(),
            SizedBox(height: 12),
            _BalancePanel(),
          ],
        ),
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MapGridPainter(
                  Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            const Center(child: Icon(Icons.my_location, size: 44)),
            Positioned(
              left: 12,
              top: 12,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  StatusChip(label: 'WS: готов', color: Colors.green),
                  StatusChip(label: 'GPS: готов', color: Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftPanel extends StatelessWidget {
  const _ShiftPanel();

  @override
  Widget build(BuildContext context) {
    final shift = context.watch<ShiftCubit>().state;
    final profile = context.watch<DriverProfileCubit>().state;
    final documents = context.watch<DocumentsCubit>().state;
    final car = context.watch<CarsCubit>().selectedCar;
    final balance = context.watch<BalanceCubit>().state.summary.currentBalance;
    final config = context.read<AppConfig>();

    return DriverSection(
      title: 'Смена',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusChip(
                label: shift.status.name,
                color: shift.status == DriverWorkStatus.online
                    ? Colors.green
                    : Colors.orange,
              ),
              const Spacer(),
              Text(
                MoneyFormatter.rub(balance),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          if (shift.message != null) ...[
            const SizedBox(height: 12),
            Text(
              shift.message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: shift.status == DriverWorkStatus.online
                ? () => context.read<ShiftCubit>().finishShift()
                : () => context.read<ShiftCubit>().startShift(
                    profile: profile,
                    documents: documents,
                    selectedCar: car,
                    locationEnabled: true,
                    hasLocationPermission: true,
                    balance: balance,
                    minimumBalance: config.minimumPrepaidBalance,
                  ),
            icon: Icon(
              shift.status == DriverWorkStatus.online
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
            ),
            label: Text(
              shift.status == DriverWorkStatus.online
                  ? 'Завершить смену'
                  : 'Выйти на линию',
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderOfferPanel extends StatelessWidget {
  const _OrderOfferPanel();

  @override
  Widget build(BuildContext context) {
    final offer = context.watch<OrdersCubit>().state;

    return DriverSection(
      title: 'Предложение заказа',
      child: offer == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Новых предложений нет'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.read<OrdersCubit>().showOffer(
                    const OrderOffer(
                      orderId: 'demo-order',
                      pickupAddress: 'ул. Ленина, 10',
                      destinationAddress: 'ул. Мира, 20',
                      price: 500,
                      distanceToPickupMeters: 1200,
                      expiresInSeconds: 20,
                      paymentMethod: PaymentMethod.card,
                    ),
                  ),
                  icon: const Icon(Icons.bolt_outlined),
                  label: const Text('Показать демо-заказ'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  offer.pickupAddress,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(offer.destinationAddress ?? 'Пункт назначения не указан'),
                const SizedBox(height: 8),
                Text(
                  '${MoneyFormatter.rub(offer.price)} · ${offer.distanceToPickupMeters} м до клиента · ${offer.expiresInSeconds} сек',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<ActiveOrderCubit>().acceptOffer(offer);
                          context.read<OrdersCubit>().clearOffer();
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Принять'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.read<OrdersCubit>().clearOffer(),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Отклонить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ActiveOrderPanel extends StatelessWidget {
  const _ActiveOrderPanel();

  @override
  Widget build(BuildContext context) {
    final order = context.watch<ActiveOrderCubit>().state;

    return DriverSection(
      title: 'Активный заказ',
      child: order == null
          ? const Text('Активного заказа нет')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  order.pickupAddress,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                StatusChip(label: order.status.name, color: Colors.blue),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _OrderAction(
                      status: DriverOrderStatus.arriving,
                      label: 'Я еду',
                      icon: Icons.route_outlined,
                    ),
                    _NavigatorButton(order: order),
                    _OrderAction(
                      status: DriverOrderStatus.arrived,
                      label: 'Я на месте',
                      icon: Icons.place_outlined,
                    ),
                    _OrderAction(
                      status: DriverOrderStatus.waiting,
                      label: 'Ожидание',
                      icon: Icons.timer_outlined,
                    ),
                    _OrderAction(
                      status: DriverOrderStatus.started,
                      label: 'Начать',
                      icon: Icons.local_taxi_outlined,
                    ),
                    _OrderAction(
                      status: DriverOrderStatus.completed,
                      label: 'Завершить',
                      icon: Icons.flag_outlined,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _NavigatorButton extends StatelessWidget {
  const _NavigatorButton({required this.order});

  final ActiveOrder order;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showNavigatorMenu(context),
      icon: const Icon(Icons.navigation_outlined),
      label: const Text('Навигатор'),
    );
  }

  Future<void> _showNavigatorMenu(BuildContext context) async {
    final selectedNavigator = await showModalBottomSheet<ExternalNavigatorApp>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.navigation_outlined),
              title: const Text('Яндекс Навигатор'),
              onTap: () => Navigator.of(
                context,
              ).pop(ExternalNavigatorApp.yandexNavigator),
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('2ГИС'),
              onTap: () =>
                  Navigator.of(context).pop(ExternalNavigatorApp.twoGis),
            ),
            ListTile(
              leading: const Icon(Icons.assistant_direction_outlined),
              title: const Text('Google Maps'),
              onTap: () =>
                  Navigator.of(context).pop(ExternalNavigatorApp.googleMaps),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || selectedNavigator == null) {
      return;
    }

    await _openNavigator(context, selectedNavigator);
  }

  Future<void> _openNavigator(
    BuildContext context,
    ExternalNavigatorApp selectedNavigator,
  ) async {
    final navigationService = context.read<ExternalNavigationService>();
    final address = order.status == DriverOrderStatus.started
        ? order.destinationAddress ?? order.pickupAddress
        : order.pickupAddress;
    final label = order.status == DriverOrderStatus.started
        ? 'Назначение'
        : 'Подача';

    try {
      await navigationService.openRoute(
        destination: NavigationTarget(label: label, address: address),
        preferredNavigator: selectedNavigator,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть навигатор: $error')),
      );
    }
  }
}

class _OrderAction extends StatelessWidget {
  const _OrderAction({
    required this.status,
    required this.label,
    required this.icon,
  });

  final DriverOrderStatus status;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        final activeOrderCubit = context.read<ActiveOrderCubit>();
        final balanceCubit = context.read<BalanceCubit>();
        final currentOrder = activeOrderCubit.state;
        activeOrderCubit.moveTo(status);
        if (status == DriverOrderStatus.completed && currentOrder != null) {
          balanceCubit.applyCompletedOrder(currentOrder.price);
        }
      },
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _DriverReadinessPanel extends StatelessWidget {
  const _DriverReadinessPanel();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DriverProfileCubit>().state;
    final documents = context.watch<DocumentsCubit>().state;
    final car = context.watch<CarsCubit>().selectedCar;

    return DriverSection(
      title: 'Готовность',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReadinessRow(
            label: 'Профиль',
            value: profile?.status.name ?? 'нет данных',
          ),
          _ReadinessRow(
            label: 'Документы',
            value:
                '${documents.where((item) => item.isApproved).length}/${documents.length}',
          ),
          _ReadinessRow(
            label: 'Автомобиль',
            value: car?.status.name ?? 'нет автомобиля',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              context.read<DriverProfileCubit>().markVerifiedForDemo();
              context.read<DocumentsCubit>().approveAllForDemo();
              context.read<CarsCubit>().approveSelectedForDemo();
            },
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Подтвердить демо-данные'),
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel();

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<BalanceCubit>().state;
    final commission = balance.lastCommission;

    return DriverSection(
      title: 'Баланс и комиссия',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReadinessRow(
            label: 'Баланс',
            value: MoneyFormatter.rub(balance.summary.currentBalance),
          ),
          _ReadinessRow(
            label: 'Комиссии',
            value: MoneyFormatter.rub(balance.summary.commissionWithheld),
          ),
          if (commission != null) ...[
            const Divider(height: 24),
            _ReadinessRow(
              label: 'Сумма заказа',
              value: MoneyFormatter.rub(commission.orderAmount),
            ),
            _ReadinessRow(
              label: 'Комиссия платформы 1%',
              value: MoneyFormatter.rub(commission.commissionAmount),
            ),
            _ReadinessRow(
              label: 'Доход после комиссии',
              value: MoneyFormatter.rub(commission.driverIncome),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 42.0;

    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
