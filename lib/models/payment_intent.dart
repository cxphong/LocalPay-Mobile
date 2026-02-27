class PaymentIntent {
  final String id;
  final double amountVnd;
  final String merchantName;
  final String status;
  final String? escrowAddress;
  final String? serializedTx;

  PaymentIntent({
    required this.id,
    required this.amountVnd,
    required this.merchantName,
    required this.status,
    this.escrowAddress,
    this.serializedTx,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    final qrData = json['qr_data'] as Map<String, dynamic>?;
    return PaymentIntent(
      id: json['id'] ?? '',
      amountVnd: (qrData?['amount_vnd'] as num?)?.toDouble() ?? 0.0,
      merchantName: qrData?['merchant_name'] ?? 'Unknown Merchant',
      status: json['status'] ?? 'INITIATED',
      escrowAddress: json['escrow_address'],
      serializedTx: json['serialized_tx'],
    );
  }
}
