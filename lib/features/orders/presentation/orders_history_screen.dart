import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'orders_controllers.dart';

class OrdersHistoryScreen extends ConsumerStatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  ConsumerState<OrdersHistoryScreen> createState() =>
      _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends ConsumerState<OrdersHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderHistoryProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderHistoryProvider);
    final orders = state.value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Заказы')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(orderHistoryProvider.notifier).refresh(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            if (orders.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('История заказов пуста'),
                ),
              );
            }
            final order = orders[index];
            return Card(
              child: ListTile(
                title: Text(order.pickupPoint.address),
                subtitle: Text(
                  '${order.destinationPoint.address}\n${order.status}',
                ),
                trailing: Text(order.price.formatted),
                isThreeLine: true,
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: orders.isEmpty ? 1 : orders.length,
        ),
      ),
    );
  }
}
