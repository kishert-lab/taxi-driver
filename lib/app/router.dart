import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/driver/presentation/driver_home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authenticated = authState.status == AuthStatus.authenticated;
      final checking = authState.status == AuthStatus.checking;
      if (checking) {
        return null;
      }
      if (!authenticated && state.matchedLocation != '/login') {
        return '/login';
      }
      if (authenticated && state.matchedLocation == '/login') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: DriverHomeScreen()),
      ),
    ],
    refreshListenable: _RouterRefresh(ref),
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
