import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth_service.dart';

class AuthState extends Equatable {
  const AuthState({required this.status, this.phone = '', this.errorMessage});

  final AuthStatus status;
  final String phone;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    String? phone,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      phone: phone ?? this.phone,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, phone, errorMessage];
}

enum AuthStatus {
  initial,
  unauthenticated,
  codeSent,
  authenticated,
  loading,
  failure,
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authService)
    : super(const AuthState(status: AuthStatus.initial));

  final AuthService _authService;

  Future<void> restoreSession() async {
    final hasSession = await _authService.hasSession();
    emit(
      state.copyWith(
        status: hasSession
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
      ),
    );
  }

  Future<void> requestCode(String phone) async {
    emit(AuthState(status: AuthStatus.loading, phone: phone));
    try {
      await _authService.requestSmsCode(phone);
      emit(AuthState(status: AuthStatus.codeSent, phone: phone));
    } catch (error) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          phone: phone,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> verifyCode(String code) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authService.verifyCode(phone: state.phone, code: code);
      emit(state.copyWith(status: AuthStatus.authenticated));
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void authenticateDemoSession() {
    emit(state.copyWith(status: AuthStatus.authenticated));
  }
}
