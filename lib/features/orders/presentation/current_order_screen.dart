import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../chat/presentation/dispatcher_chat_button.dart';
import '../application/driver_order_api_capabilities.dart';
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
                _OrderDetails(order: order, actionsDisabled: state.isLoading),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetails extends ConsumerWidget {
  const _OrderDetails({required this.order, required this.actionsDisabled});

  final DriverOrder order;
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const capabilities = DriverOrderApiCapabilities();

    bool canCall(String action) {
      return order.allowedActions.contains(action) &&
          capabilities.supportsAction(action) &&
          !actionsDisabled;
    }

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
            _Row(label: 'Статус', value: order.statusLabel),
            _Row(label: 'Цена', value: order.price.formatted),
            if (order.comment?.isNotEmpty == true)
              _Row(label: 'Комментарий', value: order.comment!),
            _Row(
              label: 'Действия',
              value: order.allowedActions.isEmpty
                  ? 'Нет доступных действий'
                  : order.allowedActions.join(', '),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canCall('accept'))
                  _ActionButton(
                    label: 'Принять',
                    icon: Icons.check_circle_outline,
                    onPressed: () => ref
                        .read(currentOrderProvider.notifier)
                        .accept(order.orderId),
                  ),
                if (canCall('reject'))
                  _ActionButton(
                    label: 'Отклонить',
                    icon: Icons.cancel_outlined,
                    onPressed: () => ref
                        .read(currentOrderProvider.notifier)
                        .reject(order.orderId, 'Не могу принять заказ'),
                  ),
                if (canCall('arriving'))
                  _ActionButton(
                    label: 'Еду к пассажиру',
                    icon: Icons.place_outlined,
                    onPressed: () => ref
                        .read(currentOrderProvider.notifier)
                        .arriving(order.orderId),
                  )
                else if (canCall('arrived'))
                  _ActionButton(
                    label: 'Ожидаю пассажира',
                    icon: Icons.place_outlined,
                    onPressed: () => ref
                        .read(currentOrderProvider.notifier)
                        .arrived(order.orderId),
                  ),
                if (order.allowedActions.contains('cancel') &&
                    !capabilities.supportsCancel)
                  const _ActionButton(
                    label: 'Отмена недоступна',
                    icon: Icons.cancel_schedule_send_outlined,
                    onPressed: null,
                  ),
                if (canCall('start'))
                  _ActionButton(
                    label: 'Пассажир сел',
                    icon: Icons.local_taxi_outlined,
                    onPressed: () => ref
                        .read(currentOrderProvider.notifier)
                        .start(order.orderId),
                  ),
                if (canCall('complete'))
                  _ActionButton(
                    label: 'Завершить заказ',
                    icon: Icons.flag_outlined,
                    onPressed: () =>
                        ref.read(currentOrderProvider.notifier).complete(order),
                  ),
                if (canCall('call_passenger'))
                  _ActionButton(
                    label: 'Позвонить',
                    icon: Icons.call_outlined,
                    onPressed: () => launchUrl(
                      Uri(scheme: 'tel', path: order.passenger.phone),
                    ),
                  ),
                DispatcherChatButton(orderId: order.orderId),
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
  final VoidCallback? onPressed;

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
