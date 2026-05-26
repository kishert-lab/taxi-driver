import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/driver_order.dart';
import 'orders_controllers.dart';

class CurrentOrderScreen extends ConsumerWidget {
  const CurrentOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(currentOrderProvider);
    final order = state.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Текущий заказ')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(currentOrderProvider.notifier).sync(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.errorMessage != null)
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (order == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Активного заказа нет'),
                  ),
                )
              else
                _OrderDetails(order: order),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetails extends ConsumerWidget {
  const _OrderDetails({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Row(label: 'ID', value: order.orderId),
            _Row(label: 'Пассажир', value: order.passenger.name),
            _Row(label: 'Телефон', value: order.passenger.phone),
            _Row(label: 'Подача', value: order.pickupPoint.address),
            _Row(label: 'Назначение', value: order.destinationPoint.address),
            _Row(label: 'Статус', value: order.status),
            _Row(label: 'Цена', value: order.price.formatted),
            if (order.comment?.isNotEmpty == true)
              _Row(label: 'Комментарий', value: order.comment!),
            _Row(label: 'Действия', value: order.allowedActions.join(', ')),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (order.allowedActions.contains('accept'))
                  _ActionButton(
                    label: 'Принять',
                    icon: Icons.check_circle_outline,
                    onPressed: () => ref
                        .read(currentOrderProvider.notifier)
                        .accept(order.orderId),
                  ),
                if (order.allowedActions.contains('reject'))
                  _ActionButton(
                    label: 'Отклонить',
                    icon: Icons.cancel_outlined,
                    onPressed: () => ref
                        .read(currentOrderProvider.notifier)
                        .reject(order.orderId, 'Too far'),
                  ),
                if (order.allowedActions.contains('arrived'))
                  _ActionButton(
                    label: 'Я на месте',
                    icon: Icons.place_outlined,
                    onPressed: () => ref
                        .read(currentOrderProvider.notifier)
                        .arrived(order.orderId),
                  ),
                if (order.allowedActions.contains('start'))
                  _ActionButton(
                    label: 'Начать',
                    icon: Icons.local_taxi_outlined,
                    onPressed: () => ref
                        .read(currentOrderProvider.notifier)
                        .start(order.orderId),
                  ),
                if (order.allowedActions.contains('complete'))
                  _ActionButton(
                    label: 'Завершить',
                    icon: Icons.flag_outlined,
                    onPressed: () =>
                        ref.read(currentOrderProvider.notifier).complete(order),
                  ),
                if (order.allowedActions.contains('call_passenger'))
                  _ActionButton(
                    label: 'Позвонить',
                    icon: Icons.call_outlined,
                    onPressed: () => launchUrl(
                      Uri(scheme: 'tel', path: order.passenger.phone),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
