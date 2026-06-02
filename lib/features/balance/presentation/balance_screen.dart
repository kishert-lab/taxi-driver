import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/balance.dart';
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
      appBar: AppBar(
        title: const Text('Баланс'),
        actions: [
          IconButton(
            onPressed: state.isLoading
                ? null
                : () => ref.read(balanceProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(balanceProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            _BalanceCard(balance: balance),
            const SizedBox(height: 12),
            Text(
              'Финансовые операции',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (transactions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Операций пока нет'),
                ),
              )
            else
              for (final transaction in transactions)
                _TransactionCard(transaction: transaction),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final DriverBalance? balance;

  @override
  Widget build(BuildContext context) {
    final updatedAt = balance?.updatedAt;
    final updatedLabel = updatedAt == null
        ? 'Не обновлялся'
        : DateFormat('dd.MM.yyyy HH:mm').format(updatedAt.toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Доступно к выплате'),
            const SizedBox(height: 4),
            Text(
              balance?.availableBalance.formatted ?? '₽0.00',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text('В ожидании: ${balance?.pendingBalance.formatted ?? '₽0.00'}'),
            const SizedBox(height: 8),
            Text('Обновлено: $updatedLabel'),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final FinancialTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(transaction.type),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Gross: ${transaction.grossMoney.formatted}'),
            Text('Commission: ${transaction.commissionMoney.formatted}'),
            Text('Net: ${transaction.netMoney.formatted}'),
            Text('Валюта: ${transaction.currency}'),
            Text(
              DateFormat(
                'dd.MM.yyyy HH:mm',
              ).format(transaction.createdAt.toLocal()),
            ),
            if (transaction.orderId?.isNotEmpty == true)
              Text('Заказ: ${transaction.orderId}'),
          ],
        ),
      ),
    );
  }
}
