import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/location/location_service.dart';
import 'core/navigation/external_navigation_service.dart';
import 'core/network/api_client.dart';
import 'core/push/push_notification_service.dart';
import 'core/storage/secure_token_storage.dart';
import 'core/websocket/driver_websocket_client.dart';
import 'features/active_order/presentation/bloc/active_order_cubit.dart';
import 'features/auth/application/auth_service.dart';
import 'features/auth/data/driver_auth_repository.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/pages/driver_login_page.dart';
import 'features/balance/application/commission_calculator.dart';
import 'features/balance/data/driver_balance_repository.dart';
import 'features/balance/presentation/bloc/balance_cubit.dart';
import 'features/cars/presentation/bloc/cars_cubit.dart';
import 'features/documents/presentation/bloc/documents_cubit.dart';
import 'features/driver_profile/data/driver_profile_repository.dart';
import 'features/driver_profile/presentation/bloc/driver_profile_cubit.dart';
import 'features/location/data/driver_location_repository.dart';
import 'features/map/presentation/pages/driver_home_page.dart';
import 'features/notifications/presentation/bloc/notifications_cubit.dart';
import 'features/orders/application/order_state_machine.dart';
import 'features/orders/data/driver_orders_repository.dart';
import 'features/orders/presentation/bloc/orders_cubit.dart';
import 'features/shift/application/driver_access_policy.dart';
import 'features/shift/data/driver_shift_repository.dart';
import 'features/shift/presentation/bloc/shift_cubit.dart';
import 'features/trips_history/presentation/bloc/trips_history_cubit.dart';
import 'shared/theme/app_theme.dart';

class TaxiDriverApp extends StatelessWidget {
  const TaxiDriverApp({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final tokenStorage = SecureTokenStorage();
    final apiClient = ApiClient(config: config, tokenStorage: tokenStorage);
    final authRepository = DriverAuthRepository(apiClient);
    final websocketClient = DriverWebSocketClient(
      config: config,
      tokenStorage: tokenStorage,
    );
    final locationService = LocationService();
    final accessPolicy = DriverAccessPolicy();
    final commissionCalculator = CommissionCalculator(platformRate: 0.01);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: config),
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider.value(value: tokenStorage),
        RepositoryProvider.value(value: websocketClient),
        RepositoryProvider.value(value: locationService),
        RepositoryProvider.value(value: const ExternalNavigationService()),
        RepositoryProvider.value(value: PushNotificationService(apiClient)),
        RepositoryProvider.value(value: DriverProfileRepository(apiClient)),
        RepositoryProvider.value(value: DriverShiftRepository(apiClient)),
        RepositoryProvider.value(value: DriverLocationRepository(apiClient)),
        RepositoryProvider.value(value: DriverOrdersRepository(apiClient)),
        RepositoryProvider.value(value: DriverBalanceRepository(apiClient)),
        RepositoryProvider.value(value: accessPolicy),
        RepositoryProvider.value(value: OrderStateMachine()),
        RepositoryProvider.value(value: commissionCalculator),
        RepositoryProvider.value(
          value: AuthService(authRepository, tokenStorage),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthCubit(context.read<AuthService>())..restoreSession(),
          ),
          BlocProvider(create: (_) => DriverProfileCubit()),
          BlocProvider(create: (_) => DocumentsCubit()),
          BlocProvider(create: (_) => CarsCubit()),
          BlocProvider(
            create: (context) =>
                ShiftCubit(accessPolicy: context.read<DriverAccessPolicy>()),
          ),
          BlocProvider(create: (_) => OrdersCubit()),
          BlocProvider(
            create: (context) =>
                ActiveOrderCubit(context.read<OrderStateMachine>()),
          ),
          BlocProvider(
            create: (context) =>
                BalanceCubit(context.read<CommissionCalculator>()),
          ),
          BlocProvider(create: (_) => TripsHistoryCubit()),
          BlocProvider(create: (_) => NotificationsCubit()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Taxi Driver',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authStatus = context.select((AuthCubit cubit) => cubit.state.status);

    if (authStatus == AuthStatus.authenticated) {
      return const DriverHomePage();
    }

    return const DriverLoginPage();
  }
}
