import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/driver_order.dart';
import 'orders_controllers.dart';

Future<void> showOrderOfferSheet(
  BuildContext context,
  WidgetRef ref,
  OrderOffer offer,
) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: true,
    builder: (_) => _OrderOfferSheet(offer: offer),
  );
}

class _OrderOfferSheet extends ConsumerStatefulWidget {
  const _OrderOfferSheet({required this.offer});

  final OrderOffer offer;

  @override
  ConsumerState<_OrderOfferSheet> createState() => _OrderOfferSheetState();
}

class _OrderOfferSheetState extends ConsumerState<_OrderOfferSheet> {
  Timer? _timer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _calculateSecondsLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _secondsLeft = _calculateSecondsLeft());
      if (_secondsLeft <= 0) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _calculateSecondsLeft() {
    final expiresAt = widget.offer.expiresAt;
    if (expiresAt == null) {
      return 20;
    }
    return expiresAt.difference(DateTime.now().toUtc()).inSeconds.clamp(0, 999);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.offer.order;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Новый заказ',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(order.pickupPoint.address),
            const SizedBox(height: 6),
            Text(order.destinationPoint.address),
            const SizedBox(height: 8),
            Text(order.price.formatted),
            if (widget.offer.distanceMeters != null)
              Text('${widget.offer.distanceMeters} м до клиента'),
            const SizedBox(height: 8),
            Text('Осталось $_secondsLeft сек.'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(currentOrderProvider.notifier)
                          .accept(order.orderId);
                      ref.read(orderOfferProvider.notifier).state = null;
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Принять'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(currentOrderProvider.notifier)
                          .reject(order.orderId, 'Too far');
                      ref.read(orderOfferProvider.notifier).state = null;
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Отклонить'),
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
