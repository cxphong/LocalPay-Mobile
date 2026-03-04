class Transaction {
  final String id;
  final String merchantId;
  final int amountVnd;
  final double amountUsdt;
  final String token;
  final String status;
  final String description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.merchantId,
    required this.amountVnd,
    required this.amountUsdt,
    required this.token,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      merchantId: json['merchant_id'] ?? '',
      amountVnd: json['amount_vnd'] ?? 0,
      amountUsdt: (json['amount_usdt'] ?? 0).toDouble(),
      token: json['token'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant_id': merchantId,
      'amount_vnd': amountVnd,
      'amount_usdt': amountUsdt,
      'token': token,
      'status': status,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
