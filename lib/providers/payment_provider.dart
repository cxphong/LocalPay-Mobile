import 'package:flutter/material.dart';
import 'package:solana/solana.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:localpay_mobile/models/payment_intent.dart';
import 'package:localpay_mobile/models/fx_quote.dart';
import 'package:localpay_mobile/models/payment_status.dart';
import 'package:localpay_mobile/services/api_service.dart';

enum PaymentStep { idle, scanned, quoted, executing, success, failure }

class PaymentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  PaymentStep step = PaymentStep.idle;
  PaymentIntent? currentIntent;
  FxQuote? currentQuote;
  PaymentStatus? finalStatus;
  String? transactionDescription;
  String? error;

  void reset() {
    step = PaymentStep.idle;
    currentIntent = null;
    currentQuote = null;
    finalStatus = null;
    transactionDescription = null;
    error = null;
    notifyListeners();
  }

  Future<void> processQR(String qrString) async {
    try {
      step = PaymentStep.idle;
      error = null;
      notifyListeners();

      currentIntent = await _apiService.startPayment(qrString);
      step = PaymentStep.scanned;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      step = PaymentStep.failure;
      notifyListeners();
    }
  }

  bool isFetchingQuote = false;

  Future<void> fetchQuote(String token) async {
    if (currentIntent == null || isFetchingQuote) return;
    try {
      isFetchingQuote = true;
      notifyListeners();
      
      currentQuote = await _apiService.getQuote(currentIntent!.id, token);
      step = PaymentStep.quoted;
      isFetchingQuote = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isFetchingQuote = false;
      notifyListeners();
    }
  }

  Future<void> confirmPayment(Ed25519HDKeyPair keyPair) async {
    if (currentIntent == null) return;
    try {
      step = PaymentStep.executing;
      notifyListeners();

      // Sign the intent ID to authorize the request
      final authSignature = await keyPair.sign(utf8.encode(currentIntent!.id));
      
      final updatedIntent = await _apiService.executePayment(
        currentIntent!.id, 
        keyPair.address, 
        base64Encode(authSignature.bytes),
        transactionDescription
      );
      currentIntent = updatedIntent;

      
      // Start polling immediately so that a simulated success can be caught fast
      pollStatus();

      if (updatedIntent.serializedTx != null) {
        final client = SolanaClient(
          rpcUrl: Uri.parse('https://api.devnet.solana.com'),
          websocketUrl: Uri.parse('wss://api.devnet.solana.com'),
        );

        final txBytes = base64Decode(updatedIntent.serializedTx!);
        final sigCount = txBytes[0];
        // Message starts after sigCount (1 byte) and signatures (N * 64 bytes)
        final messageBytes = txBytes.sublist(1 + (sigCount * 64));
        
        // Sign the message bytes with user's keypair
        final signature = await keyPair.sign(messageBytes);
        
        try {
          late String encodedTx;
          if (sigCount > 1) {
            // Gasless case: Backend is 1st signer (Fee Payer), User is 2nd signer
            final newTxBytes = Uint8List.fromList(txBytes);
            newTxBytes.setRange(1 + 64, 1 + 128, signature.bytes);
            encodedTx = base64Encode(newTxBytes);
          } else {
            // Traditional case: Only user signs
            final rawTx = Uint8List.fromList([1, ...signature.bytes, ...messageBytes]);
            encodedTx = base64Encode(rawTx);
          }

          // We don't strictly await this to block the UI, as pollStatus will catch the final result
          client.rpcClient.sendTransaction(encodedTx).then((sig) {
            debugPrint('Transaction submitted: $sig');
          }).catchError((e) {
            debugPrint('Background transaction submission failed: $e');
            // We don't set error/failure here because simulation might still succeed if triggered
          });
        } catch (e) {
          debugPrint('Transaction preparation failed: $e');
        }
      }
    } catch (e) {
      error = e.toString();
      step = PaymentStep.failure;
      notifyListeners();
    }
  }

  Future<void> pollStatus() async {
    if (currentIntent == null) return;
    try {
      while (true) {
        final status = await _apiService.checkStatus(currentIntent!.id);
        if (status.isCompleted) {
          finalStatus = status;
          step = PaymentStep.success;
          notifyListeners();
          break;
        } else if (status.isFailed) {
          finalStatus = status;
          step = PaymentStep.failure;
          notifyListeners();
          break;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      error = e.toString();
      step = PaymentStep.failure;
      notifyListeners();
    }
  }

  Future<void> simulateSuccess() async {
    if (currentIntent == null) return;
    try {
      await _apiService.simulateSuccess(currentIntent!.id);
      // Immediately poll to trigger fast success UI transition
      pollStatus();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
