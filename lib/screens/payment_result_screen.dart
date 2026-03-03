import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:localpay_mobile/providers/payment_provider.dart';

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          final isSuccess = provider.step == PaymentStep.success;
          final isExecuting = provider.step == PaymentStep.executing;
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(provider),
                  const SizedBox(height: 48),
                  Text(
                    _getTitle(provider),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getMessage(provider),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.5),
                  ),
                  const SizedBox(height: 64),
                  if (provider.step == PaymentStep.executing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: TextButton(
                        onPressed: () => provider.simulateSuccess(),
                        child: Text(
                          'SIMULATE SUCCESS (DEBUG)',
                          style: TextStyle(color: Colors.black.withOpacity(0.05), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (!isExecuting)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          provider.reset();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIcon(provider) {
    if (provider.step == PaymentStep.executing) {
      return const SizedBox(
        width: 100,
        height: 100,
        child: CircularProgressIndicator(strokeWidth: 4, color: Color(0xFF6366F1)),
      );
    }
    
    final isSuccess = provider.step == PaymentStep.success;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isSuccess ? Icons.check_rounded : Icons.close_rounded,
          size: 72,
          color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      ),
    );
  }

  String _getTitle(provider) {
    switch (provider.step) {
      case PaymentStep.executing: return 'Processing...';
      case PaymentStep.success: return 'Payment Success';
      case PaymentStep.failure: return 'Payment Failed';
      default: return 'Loading';
    }
  }

  String _getMessage(provider) {
    if (provider.step == PaymentStep.executing) {
      return 'Waiting for Solana transaction and fiat settlement confirmation.';
    }
    if (provider.step == PaymentStep.success) {
      return 'The merchant has received the fiat amount. Your escrow has been released.';
    }
    return provider.error ?? 'Something went wrong with the payment process.';
  }
}
