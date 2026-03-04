import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/solana.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:localpay_mobile/services/api_service.dart';
import 'package:localpay_mobile/models/transaction.dart';

class WalletProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'LocalPayWallet',
      publicKey: 'LocalPayWalletKey',
    ),
  );
  final _rpcUrl = 'https://api.devnet.solana.com';
  final _wsUrl = 'wss://api.devnet.solana.com';
  
  Ed25519HDKeyPair? _keyPair;
  String? _mnemonic;
  double _solBalance = 0;
  Map<String, double> _tokenBalances = {};
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  
  Ed25519HDKeyPair? get keyPair => _keyPair;
  String? get address => _keyPair?.address;
  String? get mnemonic => _mnemonic;
  double get solBalance => _solBalance;
  Map<String, double> get tokenBalances => _tokenBalances;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasWallet => _keyPair != null;

  WalletProvider() {
    loadWallet();
  }

  Future<void> loadWallet() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final mnemonic = await _storage.read(key: 'solana_mnemonic');
      if (mnemonic != null) {
        _mnemonic = mnemonic;
        _keyPair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
        await refreshBalance();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createWallet() async {
    final mnemonic = bip39.generateMnemonic();
    await importWallet(mnemonic);
  }

  Future<void> importWallet(String mnemonic) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!bip39.validateMnemonic(mnemonic)) {
        throw Exception('Invalid mnemonic phrase');
      }
      await _storage.write(key: 'solana_mnemonic', value: mnemonic);
      _mnemonic = mnemonic;
      _keyPair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
      await refreshBalance();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBalance() async {
    if (_keyPair == null) return;
    
    try {
      final balances = await _apiService.getBalances(_keyPair!.address);
      _tokenBalances = {
        for (var b in balances) b['symbol']: (b['amount'] as num).toDouble()
      };
      _solBalance = _tokenBalances['SOL'] ?? 0;
      notifyListeners();
      // Fetch history alongside balance
      await fetchHistory();
    } catch (e) {
      debugPrint('Failed to refresh balances: $e');
    }
  }

  Future<void> fetchHistory() async {
    if (_keyPair == null) return;
    
    try {
      final history = await _apiService.getTransactionHistory();
      _transactions = history;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch transaction history: $e');
    }
  }

  Future<void> requestAirdrop() async {
    if (_keyPair == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final signature = await _apiService.requestAirdrop(_keyPair!.address);
      debugPrint('Airdrop signature: $signature');
      
      // Wait for confirmation (simplified)
      await Future.delayed(const Duration(seconds: 5));
      await refreshBalance();
    } catch (e) {
      _error = 'Airdrop failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    await _storage.delete(key: 'solana_mnemonic');
    _keyPair = null;
    _mnemonic = null;
    _solBalance = 0;
    notifyListeners();
  }

  Future<void> fundServerWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final address = await _apiService.getFeePayerAddress();
      await _apiService.requestAirdrop(address);
    } catch (e) {
      _error = 'Failed to fund server: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isTransferring = false;
  bool get isTransferring => _isTransferring;

  Future<void> sendTransfer(String recipient, double amount, String tokenSymbol) async {
    if (_keyPair == null || address == null) return;
    
    try {
      _isTransferring = true;
      notifyListeners();

      // Convert amount to units (base units)
      int units;
      String mint;
      if (tokenSymbol == 'SOL') {
        units = (amount * 1e9).toInt();
        mint = 'SOL';
      } else if (tokenSymbol == 'USDC') {
        units = (amount * 1e6).toInt();
        mint = '4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU'; // Devnet USDC
      } else {
        units = (amount * 1e6).toInt();
        mint = 'EJwZgaBsW3btZHka6UnvAtvscTgt4S7nB1n3BndE3H9L'; // Devnet USDT
      }

      final serializedTx = await _apiService.buildTransferTx(address!, recipient, units, mint);
      
      final client = SolanaClient(
        rpcUrl: Uri.parse(_rpcUrl),
        websocketUrl: Uri.parse(_wsUrl),
      );

      final txBytes = base64Decode(serializedTx);
      final sigCount = txBytes[0];
      final messageBytes = txBytes.sublist(1 + (sigCount * 64));
      
      final signature = await _keyPair!.sign(messageBytes);
      
      late String encodedTx;
      if (sigCount > 1) {
        // Multi-sig (Gasless)
        final newTxBytes = Uint8List.fromList(txBytes);
        newTxBytes.setRange(1 + 64, 1 + 128, signature.bytes);
        encodedTx = base64Encode(newTxBytes);
      } else {
        // Single-sig
        final rawTx = Uint8List.fromList([1, ...signature.bytes, ...messageBytes]);
        encodedTx = base64Encode(rawTx);
      }

      final txSignature = await client.rpcClient.sendTransaction(encodedTx);
      debugPrint('Transfer submitted: $txSignature');

      // Refresh balance after short delay
      await Future.delayed(const Duration(seconds: 2));
      await refreshBalance();
      
      _isTransferring = false;
      notifyListeners();
    } catch (e) {
      _isTransferring = false;
      notifyListeners();
      rethrow;
    }
  }
}
