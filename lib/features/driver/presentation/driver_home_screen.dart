import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../balance/presentation/balance_controller.dart';
import '../../balance/presentation/balance_screen.dart';
import '../../orders/presentation/order_offer_sheet.dart';
import '../../orders/presentation/orders_controllers.dart';
import '../../orders/presentation/orders_history_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../realtime/realtime_controller.dart';
import '../domain/driver_profile.dart';
import 'dashboard_screen.dart';
import 'driver_controllers.dart';
import 'location_controller.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  var _index = 0;
  Timer? _offersPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverProfileProvider.notifier).load();
      ref.read(realtimeControllerProvider.notifier).start();
      ref.read(currentOrderProvider.notifier).sync();
      ref.read(orderOffersSynchronizerProvider).sync();
      ref.read(balanceProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _stopOffersPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        _stopOffersPolling();
        ref.read(locationControllerProvider.notifier).stop();
        ref.read(realtimeControllerProvider.notifier).stop();
      }
    });

    ref.listen(orderOfferProvider, (previous, next) {
      if (next != null) {
        showOrderOfferSheet(context, ref, next);
      }
    });

    ref.listen(driverProfileProvider, (previous, next) {
      final profile = next.value;
      if (profile == null) {
        return;
      }
      ref
          .read(driverStatusControllerProvider.notifier)
          .syncFromProfile(profile);
    });

    ref.listen(driverStatusControllerProvider, (previous, next) {
      final status = next.value;
      if (status == null) {
        return;
      }
      if (status.canSendLocation) {
        ref.read(locationControllerProvider.notifier).start(status);
        _startOffersPolling();
        return;
      }
      _stopOffersPolling();
      ref.read(locationControllerProvider.notifier).stop();
    });

    ref.listen(currentOrderProvider, (previous, next) {
      final order = next.value;
      final previousOrder = previous?.value;
      if (previousOrder != null && order == null) {
        ref.read(driverProfileProvider.notifier).refresh();
      }
      final locationState = ref.read(locationControllerProvider);
      if (order?.isInProgress != true ||
          locationState.activeOrderId == order?.orderId) {
        return;
      }
      ref
          .read(locationControllerProvider.notifier)
          .startTripTracking(order!.orderId);
    });

    final screens = const [
      DashboardScreen(),
      OrdersHistoryScreen(),
      BalanceScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'История',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Баланс',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  void _startOffersPolling() {
    if (_offersPollTimer?.isActive == true) {
      return;
    }
    ref.read(orderOffersSynchronizerProvider).sync();
    _offersPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.read(orderOffersSynchronizerProvider).sync();
    });
  }

  void _stopOffersPolling() {
    _offersPollTimer?.cancel();
    _offersPollTimer = null;
  }
}
