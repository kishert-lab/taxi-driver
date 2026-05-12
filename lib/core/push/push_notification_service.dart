import 'package:firebase_messaging/firebase_messaging.dart';

import '../network/api_client.dart';

class PushNotificationService {
  PushNotificationService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> registerDriverPushToken() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      return;
    }

    await _apiClient.post<void>(
      '/api/v1/device/push-token',
      data: {'token': token, 'platform': 'driver_app'},
    );
  }
}
