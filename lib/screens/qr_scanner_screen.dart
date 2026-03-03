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
      backgroundColor: Colors.black, // Scanner needs dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      extendBodyBehindAppBar: true,
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
                  _isProcessing = true;
                  setState(() {});
                  await controller.stop();
                  if (!mounted) return;
                  await context.read<PaymentProvider>().processQR(code);
                  if (mounted) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaymentQuoteScreen()),
                    );
                    _isProcessing = false;
                    setState(() {});
                    controller.start();
                  }
                }
              }
            },
          ),
          _buildScannerOverlay(),
          _buildScannerFrame(),
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(40),
              ),
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
              borderRadius: BorderRadius.circular(40),
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
          const SizedBox(height: 48),
          const Text(
            'Center the QR Code in the frame',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Scanning is automatic',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
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
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF6366F1), width: 6),
              left: BorderSide(color: Color(0xFF6366F1), width: 6),
            ),
          ),
        ),
      ),
    );
  }
}
