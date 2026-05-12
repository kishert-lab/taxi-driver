import '../../../core/network/api_client.dart';
import '../domain/auth_tokens.dart';

class DriverAuthRepository {
  DriverAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> requestSmsCode(String phone) async {
    await _apiClient.post<void>(
      '/api/v1/auth/driver/login',
      data: {'phone': phone},
    );
  }

  Future<AuthTokens> verifyCode({
    required String phone,
    required String code,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/verify-code',
      data: {'phone': phone, 'code': code, 'role': 'driver'},
    );

    return AuthTokens.fromJson(response.data ?? const {});
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    return AuthTokens.fromJson(response.data ?? const {});
  }
}
