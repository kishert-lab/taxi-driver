import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../domain/auth_tokens.dart';

class DriverAuthRepository {
  DriverAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> requestSmsCode(String phone) async {
    await _apiClient.post<void>(
      ApiEndpoints.authLogin,
      data: {'phone': phone, 'role': 'driver'},
    );
  }

  Future<AuthTokens> verifyCode({
    required String phone,
    required String code,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authVerifyCode,
      data: {'phone': phone, 'code': code, 'role': 'driver'},
    );

    return AuthTokens.fromJson(ApiResponse.data(response.data));
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authRefresh,
      data: {'refresh_token': refreshToken},
    );

    return AuthTokens.fromJson(ApiResponse.data(response.data));
  }
}
