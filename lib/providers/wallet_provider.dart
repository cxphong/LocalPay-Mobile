import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/solana.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:localpay_mobile/services/api_service.dart';

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
  bool _isLoading = false;
  String? _error;

  Ed25519HDKeyPair? get keyPair => _keyPair;
  String? get address => _keyPair?.address;
  String? get mnemonic => _mnemonic;
  double get solBalance => _solBalance;
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final mnemonic = bip39.generateMnemonic();
      await _storage.write(key: 'solana_mnemonic', value: mnemonic);
      _mnemonic = mnemonic;
      _keyPair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
      await refreshBalance();
    } catch (e) {
      _error = 'Failed to create wallet: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBalance() async {
    if (_keyPair == null) return;
    
    try {
      final balance = await _apiService.getBalance(_keyPair!.address);
      _solBalance = balance;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh balance: $e');
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
}
