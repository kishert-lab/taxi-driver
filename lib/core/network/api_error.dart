class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.requestId,
    this.details,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final String? requestId;
  final Map<String, dynamic>? details;

  bool get isUnauthorized => statusCode == 401 || code == 'UNAUTHORIZED';
  bool get isRateLimited => statusCode == 429 || code == 'RATE_LIMITED';
  bool get isNotImplemented => statusCode == 501 || code == 'NOT_IMPLEMENTED';
  bool get isDriverNotAvailable => code == 'DRIVER_NOT_AVAILABLE';

  String get userMessage {
    if (isNotImplemented) {
      return 'Функция пока недоступна на сервере.';
    }
    if (isDriverNotAvailable) {
      return 'Вы не можете выйти на линию. Проверьте статус проверки документов и автомобиля.';
    }
    return message;
  }

  @override
  String toString() {
    final suffix = requestId == null ? '' : ' request_id=$requestId';
    return 'ApiException($statusCode, $code): $message$suffix';
  }
}
