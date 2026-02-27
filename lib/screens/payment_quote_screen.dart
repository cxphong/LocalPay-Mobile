import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solana/solana.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:localpay_mobile/providers/payment_provider.dart';
import 'package:localpay_mobile/providers/wallet_provider.dart';
import 'package:localpay_mobile/screens/payment_result_screen.dart';
import 'package:localpay_mobile/screens/wallet_setup_screen.dart';

class PaymentQuoteScreen extends StatefulWidget {
  const PaymentQuoteScreen({super.key});

  @override
  State<PaymentQuoteScreen> createState() => _PaymentQuoteScreenState();
}

class _PaymentQuoteScreenState extends State<PaymentQuoteScreen> {
  String selectedToken = 'USDT';
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  Timer? _timer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchQuote(selectedToken);
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final provider = context.read<PaymentProvider>();
      final quote = provider.currentQuote;
      if (quote != null) {
        final diff = quote.expiresAt.difference(DateTime.now()).inSeconds;
        if (mounted) {
          setState(() {
            _secondsRemaining = diff > 0 ? diff : 0;
          });
        }
        
        if (diff <= 0 && !provider.isFetchingQuote && provider.step != PaymentStep.executing) {
          provider.fetchQuote(selectedToken);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Confirm Payment'),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.currentIntent == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final intent = provider.currentIntent!;
          final quote = provider.currentQuote;
          final isFetching = provider.isFetchingQuote;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMerchantCard(intent),
                const SizedBox(height: 32),
                const Text(
                  'Select Payment Token',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                _buildTokenSelector(),
                const Spacer(),
                if (context.watch<WalletProvider>().hasWallet) ...[
                  if (quote != null) 
                    _buildQuoteDetails(quote, isFetching)
                  else
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )),
                  const SizedBox(height: 24),
                  _buildPayButton(provider),
                ] else 
                  _buildNoWalletWarning(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoWalletWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          const Text(
            'No wallet setup',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You need to create a wallet and add funds (Airdrop) before you can make a payment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WalletSetupScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('SETUP WALLET', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(intent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PAYING TO', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(intent.merchantName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          const Text('AMOUNT DUE', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(currencyFormat.format(intent.amountVnd), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
        ],
      ),
    );
  }

  Widget _buildTokenSelector() {
    return Row(
      children: ['USDT', 'USDC', 'SOL'].map((token) {
        final isSelected = selectedToken == token;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => selectedToken = token);
              context.read<PaymentProvider>().fetchQuote(token);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
              ),
              child: Center(
                child: Text(
                  token,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuoteDetails(quote, bool isFetching) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Rate', style: TextStyle(color: Colors.white54)),
                  const SizedBox(width: 8),
                  if (isFetching) 
                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54)),
                ],
              ),
              Text('1 ${quote.token} = ${currencyFormat.format(quote.rate)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('You Pay', style: TextStyle(color: Colors.white54)),
              Text('${quote.amountCrypto} ${quote.token}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _secondsRemaining / 30,
            backgroundColor: Colors.white10,
            color: _secondsRemaining < 5 ? Colors.redAccent : const Color(0xFF6366F1),
          ),
          const SizedBox(height: 4),
          Text(
            'Quote expires in $_secondsRemaining s',
            style: TextStyle(
              fontSize: 11,
              color: _secondsRemaining < 5 ? Colors.redAccent : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(provider) {
    final isLoading = provider.step == PaymentStep.executing;
    final isQuoteExpired = _secondsRemaining <= 0;

    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: (isLoading || isQuoteExpired) ? null : () async {
          final wallet = context.read<WalletProvider>();
          await provider.confirmPayment(wallet.keyPair!);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PaymentResultScreen()),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(isQuoteExpired ? 'REFRESHING QUOTE...' : 'CONFIRM PAYMENT', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    );
  }
}
