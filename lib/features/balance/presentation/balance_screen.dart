import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'balance_controller.dart';

class BalanceScreen extends ConsumerStatefulWidget {
  const BalanceScreen({super.key});

  @override
  ConsumerState<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends ConsumerState<BalanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(balanceProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(balanceProvider);
    final data = state.value;
    final balance = data?.balance;
    final transactions = data?.transactions ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Баланс')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(balanceProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Доступно'),
                    Text(
                      balance?.availableBalance.formatted ?? '0 ₽',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'В ожидании: ${balance?.pendingBalance.formatted ?? '0 ₽'}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Транзакции', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (transactions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Транзакций нет'),
                ),
              )
            else
              for (final transaction in transactions)
                Card(
                  child: ListTile(
                    title: Text(transaction.description ?? transaction.type),
                    subtitle: Text(
                      DateFormat(
                        'dd.MM.yyyy HH:mm',
                      ).format(transaction.createdAt),
                    ),
                    trailing: Text(transaction.amount.formatted),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
