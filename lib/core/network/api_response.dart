class ApiResponse<T> {
  const ApiResponse({required this.data, this.requestId});

  final T data;
  final String? requestId;

  static String? requestIdFrom(Map<String, dynamic>? json) {
    final meta = json?['meta'];
    if (meta is Map) {
      return meta['request_id'] as String?;
    }
    return null;
  }
}
