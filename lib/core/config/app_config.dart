class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.websocketUrl,
    required this.orderOfferTimeoutSeconds,
    required this.minimumPrepaidBalance,
  });

  final String apiBaseUrl;
  final String websocketUrl;
  final int orderOfferTimeoutSeconds;
  final int minimumPrepaidBalance;

  factory AppConfig.development() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://192.168.0.50:8083/',
      ),
      websocketUrl: String.fromEnvironment(
        'WS_URL',
        defaultValue: 'ws://192.168.0.50:8083/api/v1/ws',
      ),
      orderOfferTimeoutSeconds: 20,
      minimumPrepaidBalance: 0,
    );
  }
}
