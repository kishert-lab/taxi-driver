import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'current_order_screen.dart';
import 'orders_controllers.dart';

class CurrentOrderCard extends ConsumerWidget {
  const CurrentOrderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(currentOrderProvider).value;

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
                  Text(order.price.formatted),
                  const SizedBox(height: 12),
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
