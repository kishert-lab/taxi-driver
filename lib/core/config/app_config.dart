import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({required this.baseUrl, required this.websocketUrl});

  final String baseUrl;
  final String websocketUrl;

  static const development = AppConfig(
    baseUrl: String.fromEnvironment(
      'BASE_URL',
      //defaultValue: 'https://taxi.dev.wkfc.ru/api/v1',
        defaultValue: 'http://192.168.0.50:8080/api/v1',
    ),
    websocketUrl: String.fromEnvironment(
      'WS_URL',
      //defaultValue: 'wss://taxi.dev.wkfc.ru/api/v1/ws',
      defaultValue: 'ws://192.168.0.50:8080/api/v1/ws',
    ),
  );
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.development);

