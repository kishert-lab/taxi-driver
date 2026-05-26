import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/domain/auth_tokens.dart';
import '../config/app_config.dart';
import '../storage/secure_token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required AppConfig config,
    required SecureTokenStorage tokenStorage,
    required void Function() onSessionExpired,
  }) : _dio = dio,
       _config = config,
       _tokenStorage = tokenStorage,
       _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final AppConfig _config;
  final SecureTokenStorage _tokenStorage;
  final void Function() _onSessionExpired;
  Future<AuthTokens?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && options.extra['skipAuth'] != true) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    final skipAuth = err.requestOptions.extra['skipAuth'] == true;
    if (statusCode != 401 || alreadyRetried || skipAuth) {
      handler.next(err);
      return;
    }

    final tokens = await _refreshTokens();
    if (tokens == null) {
      await _tokenStorage.clear();
      _onSessionExpired();
      handler.next(err);
      return;
    }

    final retryOptions = err.requestOptions;
    retryOptions.extra['retried'] = true;
    retryOptions.headers['Authorization'] = 'Bearer ${tokens.accessToken}';

    try {
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<AuthTokens?> _refreshTokens() {
    _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  Future<AuthTokens?> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      return null;
    }

    try {
      final response = await Dio(BaseOptions(baseUrl: _config.baseUrl))
          .post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: Options(extra: {'skipAuth': true}),
          );
      final data = response.data?['data'];
      if (data is! Map) {
        return null;
      }
      final tokens = AuthTokens.fromJson(Map<String, dynamic>.from(data));
      await _tokenStorage.saveTokens(tokens);
      return tokens;
    } catch (_) {
      return null;
    }
  }
}
