import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../storage/secure_token_storage.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required SecureTokenStorage tokenStorage,
  }) : _tokenStorage = tokenStorage,
       dio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 20),
           sendTimeout: const Duration(seconds: 20),
           headers: const {'Accept': 'application/json'},
         ),
       ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final tokens = await _tokenStorage.readTokens();
          if (tokens != null) {
            options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final SecureTokenStorage _tokenStorage;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _guard(
      () => dio.get<T>(path, queryParameters: queryParameters),
      'GET $path failed',
    );
  }

  Future<Response<T>> post<T>(String path, {Object? data, Options? options}) {
    return _guard(
      () => dio.post<T>(path, data: data, options: options),
      'POST $path failed',
    );
  }

  Future<Response<T>> put<T>(String path, {Object? data}) {
    return _guard(() => dio.put<T>(path, data: data), 'PUT $path failed');
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) {
    return _guard(() => dio.patch<T>(path, data: data), 'PATCH $path failed');
  }

  Future<Response<T>> delete<T>(String path) {
    return _guard(() => dio.delete<T>(path), 'DELETE $path failed');
  }

  Future<Response<T>> _guard<T>(
    Future<Response<T>> Function() request,
    String context,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw UnauthorizedException(context, cause: error);
      }
      throw NetworkException(context, cause: error);
    } catch (error) {
      throw AppException(context, cause: error);
    }
  }
}
