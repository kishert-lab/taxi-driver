import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/presentation/dispatcher_chat_button.dart';
import '../application/driver_order_api_capabilities.dart';
import 'current_order_screen.dart';
import 'orders_controllers.dart';

class CurrentOrderCard extends ConsumerWidget {
  const CurrentOrderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(currentOrderProvider);
    final order = orderState.value;
    const capabilities = DriverOrderApiCapabilities();

    bool canCall(String action) {
      return order?.allowedActions.contains(action) == true &&
          capabilities.supportsAction(action) &&
          !orderState.isLoading;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: order == null
            ? const Text('Активного заказа нет')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Текущий заказ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(order.pickupPoint.address),
                  const SizedBox(height: 4),
                  Text(order.destinationPoint.address),
                  const SizedBox(height: 8),
                  Text(order.statusLabel),
                  const SizedBox(height: 4),
                  Text(order.price.formatted),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (canCall('arriving'))
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(currentOrderProvider.notifier)
                              .arriving(order.orderId),
                          icon: const Icon(Icons.place_outlined),
                          label: const Text('Еду к пассажиру'),
                        )
                      else if (canCall('arrived'))
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(currentOrderProvider.notifier)
                              .arrived(order.orderId),
                          icon: const Icon(Icons.place_outlined),
                          label: const Text('Ожидаю пассажира'),
                        ),
                      if (canCall('start'))
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(currentOrderProvider.notifier)
                              .start(order.orderId),
                          icon: const Icon(Icons.local_taxi_outlined),
                          label: const Text('Пассажир сел'),
                        ),
                      if (canCall('complete'))
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(currentOrderProvider.notifier)
                              .complete(order),
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Завершить заказ'),
                        ),
                    ],
                  ),
                  if (canCall('arriving') ||
                      canCall('arrived') ||
                      canCall('start') ||
                      canCall('complete'))
                    const SizedBox(height: 8),
                  DispatcherChatButton(orderId: order.orderId),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CurrentOrderScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('Открыть заказ'),
                  ),
                ],
              ),
      ),
    );
  }
}
