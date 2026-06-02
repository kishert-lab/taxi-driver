import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/chat_models.dart';

abstract class ChatRepository {
  Future<ChatThread> dispatcherMessages(String orderId, {int limit = 50});
  Future<ChatMessage> sendDispatcherMessage(String orderId, String body);
}

class TaxiChatRepository implements ChatRepository {
  TaxiChatRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ChatThread> dispatcherMessages(String orderId, {int limit = 50}) {
    return _apiClient.get(
      ApiEndpoints.driverDispatcherChatMessages(orderId),
      queryParameters: {'limit': limit},
      parser: (json) => ChatThread.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
  }

  @override
  Future<ChatMessage> sendDispatcherMessage(String orderId, String body) {
    return _apiClient.post(
      ApiEndpoints.driverDispatcherChatMessages(orderId),
      data: {'body': body},
      parser: (json) => ChatMessage.fromJson(
        Map<String, dynamic>.from(json as Map? ?? const {}),
      ),
    );
  }
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => TaxiChatRepository(ref.watch(apiClientProvider)),
);
