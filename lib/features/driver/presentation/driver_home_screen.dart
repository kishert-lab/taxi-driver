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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverProfileProvider.notifier).load();
      ref.read(realtimeControllerProvider.notifier).start();
      ref.read(balanceProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        ref.read(realtimeControllerProvider.notifier).stop();
      }
    });

    ref.listen(orderOfferProvider, (previous, next) {
      if (next != null) {
        showOrderOfferSheet(context, ref, next);
      }
    });

    ref.listen(driverStatusControllerProvider, (previous, next) {
      final status = next.value;
      if (status == null) {
        return;
      }
      if (status.canSendLocation) {
        ref.read(locationControllerProvider.notifier).start(status);
      } else {
        ref.read(locationControllerProvider.notifier).stop();
      }
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
            label: 'Заказы',
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
}
