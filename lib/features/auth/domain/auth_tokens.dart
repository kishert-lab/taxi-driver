class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 0,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
    );
  }
}
