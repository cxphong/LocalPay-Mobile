class PaymentStatus {
  final String status;
  final String? escrowAddress;
  final String? payoutId;

  PaymentStatus({
    required this.status,
    this.escrowAddress,
    this.payoutId,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isProcessing => status == 'PROCESSING' || status == 'PENDING';
  bool get isFailed => status == 'FAILED' || status == 'ESCROW_FAILED';

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      status: json['status'],
      escrowAddress: json['escrow_address'],
      payoutId: json['payout_id'],
    );
  }
}
