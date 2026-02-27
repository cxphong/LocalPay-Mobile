class FxQuote {
  final double amountCrypto;
  final double rate;
  final String token;
  final DateTime expiresAt;

  FxQuote({
    required this.amountCrypto,
    required this.rate,
    required this.token,
    required this.expiresAt,
  });

  factory FxQuote.fromJson(Map<String, dynamic> json, String token) {
    return FxQuote(
      amountCrypto: (json['required_amount'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      token: token,
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }
}
