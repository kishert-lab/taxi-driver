import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/driver_location_outbox_store.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../domain/auth_tokens.dart';

abstract class AuthRepository {
  Future<AuthTokens> login({required String phone, required String password});
  Future<AuthTokens> refresh();
  Future<void> logout();
  Future<void> clearSession();
  Future<AuthTokens?> restoreSession();
}

class TaxiAuthRepository implements AuthRepository {
  TaxiAuthRepository(this._apiClient, this._tokenStorage, this._outboxStore);

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;
  final DriverLocationOutboxStore _outboxStore;

  @override
  Future<AuthTokens> login({
    required String phone,
    required String password,
  }) async {
    final tokens = await _apiClient.post<AuthTokens>(
      '/auth/login',
      data: {'phone': phone, 'password': password, 'role': 'driver'},
      parser: (json) => AuthTokens.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }

  @override
  Future<AuthTokens> refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      throw StateError('refresh token is missing');
    }

    final tokens = await _apiClient.post<AuthTokens>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(extra: {'skipAuth': true}),
      parser: (json) => AuthTokens.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _apiClient.post<void>(
          '/auth/logout',
          data: {'refresh_token': refreshToken},
          options: Options(extra: {'skipAuth': true}),
          parser: (_) {},
        );
      } catch (_) {
        // Local logout must still clear tokens if server logout is unavailable.
      }
    }
    await _tokenStorage.clear();
    await _outboxStore.clear();
  }

  @override
  Future<void> clearSession() {
    return Future.wait<void>([_tokenStorage.clear(), _outboxStore.clear()]);
  }

  @override
  Future<AuthTokens?> restoreSession() {
    return _tokenStorage.readTokens();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return TaxiAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureTokenStorageProvider),
    ref.watch(driverLocationOutboxStoreProvider),
  );
});
