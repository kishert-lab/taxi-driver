import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../session/session_expiration_notifier.dart';
import '../storage/secure_token_storage.dart';
import 'api_error.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required SecureTokenStorage tokenStorage,
    required void Function() onSessionExpired,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        config: config,
        tokenStorage: tokenStorage,
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  late final Dio dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? json) parser,
  }) {
    return _guard(
      () =>
          dio.get<Map<String, dynamic>>(path, queryParameters: queryParameters),
      parser,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    required T Function(Object? json) parser,
    Options? options,
  }) {
    return _guard(
      () => dio.post<Map<String, dynamic>>(path, data: data, options: options),
      parser,
    );
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    required T Function(Object? json) parser,
  }) {
    return _guard(
      () => dio.patch<Map<String, dynamic>>(path, data: data),
      parser,
    );
  }

  Future<T> _guard<T>(
    Future<Response<Map<String, dynamic>>> Function() request,
    T Function(Object? json) parser,
  ) async {
    try {
      final response = await request();
      return parser(response.data?['data']);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final body = error.response?.data;
    if (body is Map) {
      final json = Map<String, dynamic>.from(body);
      final errorBody = json['error'];
      final meta = json['meta'];
      return ApiException(
        statusCode: error.response?.statusCode,
        code: errorBody is Map ? errorBody['code'] as String? : null,
        message: errorBody is Map
            ? errorBody['message'] as String? ?? 'Ошибка сервера'
            : 'Ошибка сервера',
        details: errorBody is Map && errorBody['details'] is Map
            ? Map<String, dynamic>.from(errorBody['details'] as Map)
            : null,
        requestId: meta is Map ? meta['request_id'] as String? : null,
      );
    }
    return ApiException(
      statusCode: error.response?.statusCode,
      message: error.message ?? 'Ошибка сети',
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
    onSessionExpired: () {
      ref.read(sessionExpirationProvider.notifier).markExpired();
    },
  );
});
