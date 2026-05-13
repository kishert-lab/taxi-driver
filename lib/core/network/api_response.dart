import '../errors/app_exception.dart';

class ApiResponse {
  const ApiResponse._();

  static Map<String, dynamic> data(Map<String, dynamic>? response) {
    final payload = response?['data'];
    if (payload is Map<String, dynamic>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }

    throw const AppException('backend response does not contain object data');
  }

  static List<dynamic> listField(
    Map<String, dynamic>? response,
    String fieldName,
  ) {
    final payload = data(response)[fieldName];
    if (payload is List) {
      return payload;
    }

    return const [];
  }
}
