import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:localpay_mobile/providers/payment_provider.dart';
import 'package:localpay_mobile/screens/payment_quote_screen.dart';
import 'package:localpay_mobile/screens/wallet_setup_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  _isProcessing = true; // Set immediately without waiting for setState microtask
                  setState(() {});
                  
                  await controller.stop(); // Stop scanning immediately
                  
                  if (!mounted) return;
                  await context.read<PaymentProvider>().processQR(code);
                  
                  if (mounted) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaymentQuoteScreen()),
                    );
                    // When back from the next screen, resume scanning
                    _isProcessing = false;
                    setState(() {});
                    controller.start();
                  }
                }
              }
            },
          ),
          _buildOverlay(),
          _buildHeader(),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF6366F1), width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              _ScannerCorner(top: 0, left: 0, rotation: 0),
              _ScannerCorner(top: 0, right: 0, rotation: 1.5708),
              _ScannerCorner(bottom: 0, left: 0, rotation: 4.7124),
              _ScannerCorner(bottom: 0, right: 0, rotation: 3.14159),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LocalPay Go',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan VietQR to pay with Crypto',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 32, color: Color(0xFF6366F1)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WalletSetupScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  final double? top, bottom, left, right;
  final double rotation;

  const _ScannerCorner({this.top, this.bottom, this.left, this.right, required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF6366F1), width: 4),
              left: BorderSide(color: Color(0xFF6366F1), width: 4),
            ),
          ),
        ),
      ),
    );
  }
}
