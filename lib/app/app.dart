import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session/session_expiration_notifier.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/realtime/realtime_controller.dart';
import 'router.dart';
import 'theme.dart';

class TaxiDriverApplication extends ConsumerWidget {
  const TaxiDriverApplication({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(sessionExpirationProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      ref.read(realtimeControllerProvider.notifier).stop();
      ref.read(authControllerProvider.notifier).forceLogout();
    });

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Taxi Driver',
      theme: buildTaxiDriverTheme(),
      routerConfig: router,
    );
  }
}
