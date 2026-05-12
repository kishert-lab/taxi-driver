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
        defaultValue: 'https://api.example.com',
      ),
      websocketUrl: String.fromEnvironment(
        'WS_URL',
        defaultValue: 'wss://api.example.com/api/v1/driver/ws',
      ),
      orderOfferTimeoutSeconds: 20,
      minimumPrepaidBalance: 0,
    );
  }
}
