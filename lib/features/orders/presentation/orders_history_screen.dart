import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/driver_order.dart';
import 'order_details_screen.dart';
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
      appBar: AppBar(title: const Text('История')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(orderHistoryProvider.notifier).refresh(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.isEmpty ? 1 : orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (orders.isEmpty) {
              return _EmptyHistory(message: state.errorMessage);
            }
            final order = orders[index];
            return _HistoryOrderCard(order: order);
          },
        ),
      ),
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  const _HistoryOrderCard({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    final date = order.displayDate;
    final dateLabel = date == null
        ? 'Дата неизвестна'
        : DateFormat('dd.MM.yyyy HH:mm').format(date.toLocal());

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          order.pickupPoint.address,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.destinationPoint.address),
              const SizedBox(height: 8),
              Text(dateLabel),
              const SizedBox(height: 4),
              Text(order.statusLabel),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              order.price.formatted,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OrderDetailsScreen(orderId: order.orderId),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message ?? 'История поездок пуста'),
      ),
    );
  }
}
