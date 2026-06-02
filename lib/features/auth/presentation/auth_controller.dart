import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../driver/data/driver_repository.dart';
import '../data/auth_repository.dart';

enum AuthStatus { checking, unauthenticated, authenticated, loading }

class AuthState {
  const AuthState({required this.status, this.errorMessage});

  final AuthStatus status;
  final String? errorMessage;

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(status: status ?? this.status, errorMessage: errorMessage);
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._driverRepository)
    : super(const AuthState(status: AuthStatus.checking));

  final AuthRepository _repository;
  final DriverRepository _driverRepository;

  Future<void> restoreSession() async {
    final tokens = await _repository.restoreSession();
    state = AuthState(
      status: tokens == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated,
    );
  }

  Future<void> login({required String phone, required String password}) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repository.login(phone: phone, password: password);
      state = const AuthState(status: AuthStatus.authenticated);
    } on ApiException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: error.userMessage,
      );
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Не удалось войти: $error',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _goOfflineBeforeLogout();
      await _repository.logout();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _goOfflineBeforeLogout() async {
    try {
      await _driverRepository.goOffline();
    } catch (_) {
      // Logout must still clear the local session if the offline request fails.
    }
  }

  void forceLogout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final controller = AuthController(
      ref.watch(authRepositoryProvider),
      ref.watch(driverRepositoryProvider),
    );
    controller.restoreSession();
    return controller;
  },
);
