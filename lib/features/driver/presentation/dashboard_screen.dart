import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ws/ws_client.dart';
import '../../orders/presentation/current_order_card.dart';
import '../domain/driver_profile.dart';
import 'driver_controllers.dart';
import 'location_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(driverProfileProvider).value;
    final statusState = ref.watch(driverStatusControllerProvider);
    final locationState = ref.watch(locationControllerProvider);
    final websocketState = ref.watch(wsClientProvider);
    final status = statusState.value ?? profile?.status;
    final online = status?.canSendLocation == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(driverProfileProvider.notifier).load();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusPanel(
                statusLabel: status?.label ?? 'Неизвестно',
                online: online,
                loading: statusState.isLoading,
                errorMessage: statusState.errorMessage,
                connectionLabel: websocketState.label,
                locationTracking: locationState.isTracking,
                onToggle: () {
                  final controller = ref.read(
                    driverStatusControllerProvider.notifier,
                  );
                  online ? controller.goOffline() : controller.goOnline();
                },
              ),
              const SizedBox(height: 12),
              const CurrentOrderCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.statusLabel,
    required this.online,
    required this.loading,
    required this.connectionLabel,
    required this.locationTracking,
    required this.onToggle,
    this.errorMessage,
  });

  final String statusLabel;
  final bool online;
  final bool loading;
  final String connectionLabel;
  final bool locationTracking;
  final VoidCallback onToggle;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  online ? Icons.check_circle : Icons.pause_circle,
                  color: online ? Colors.green : Colors.orange,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SmallStatus(label: connectionLabel),
                _SmallStatus(
                  label: locationTracking
                      ? 'GPS отправляется'
                      : 'GPS остановлен',
                ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loading ? null : onToggle,
              icon: Icon(
                online ? Icons.stop_circle_outlined : Icons.play_arrow,
              ),
              label: Text(online ? 'Уйти с линии' : 'Выйти на линию'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStatus extends StatelessWidget {
  const _SmallStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(visualDensity: VisualDensity.compact, label: Text(label));
  }
}
