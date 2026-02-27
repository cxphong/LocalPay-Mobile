import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:localpay_mobile/providers/payment_provider.dart';

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          final isSuccess = provider.step == PaymentStep.success;
          final isExecuting = provider.step == PaymentStep.executing;
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(provider),
                  const SizedBox(height: 32),
                  Text(
                    _getTitle(provider),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getMessage(provider),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 48),
                  if (provider.step == PaymentStep.executing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextButton(
                        onPressed: () => provider.simulateSuccess(),
                        child: const Text(
                          'SIMULATE SUCCESS (DEBUG)',
                          style: TextStyle(color: Colors.white24, fontSize: 12),
                        ),
                      ),
                    ),
                  if (!isExecuting)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          provider.reset();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF6366F1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: CircularProgressIndicator(strokeWidth: 8, color: Color(0xFF6366F1)),
      );
    }
    
    final isSuccess = provider.step == PaymentStep.success;
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
        size: 80,
        color: isSuccess ? Colors.green : Colors.red,
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
