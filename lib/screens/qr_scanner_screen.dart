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
          _buildScannerFrame(),
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

  Widget _buildScannerFrame() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Stack(
              children: [
                _ScannerCorner(top: -2, left: -2, rotation: 0),
                _ScannerCorner(top: -2, right: -2, rotation: 1.5708),
                _ScannerCorner(bottom: -2, left: -2, rotation: 4.7124),
                _ScannerCorner(bottom: -2, right: -2, rotation: 3.14159),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Align QR code within frame',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
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
