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
  final _descriptionController = TextEditingController();

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
    _descriptionController.dispose();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.currentIntent == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          final intent = provider.currentIntent!;
          final quote = provider.currentQuote;
          final isFetching = provider.isFetchingQuote;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildMerchantHeader(intent),
                  const SizedBox(height: 40),
                  if (quote != null) 
                    _buildHeroAmount(quote)
                  else
                    const Center(child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF6366F1)),
                    )),
                  const SizedBox(height: 48),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Payment Method',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTokenSelector(),
                  const SizedBox(height: 32),
                  _buildDescriptionField(),
                  const SizedBox(height: 32),
                  if (quote != null) ...[
                    _buildQuoteBreakdown(quote, isFetching),
                    const SizedBox(height: 24),
                    _buildBalanceWarning(quote),
                    const SizedBox(height: 24),
                    if (context.watch<WalletProvider>().hasWallet)
                      _buildPayButton(provider, quote)
                    else 
                      _buildNoWalletWarning(context),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
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
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD97706), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Wallet Required',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'You must set up a wallet and add test funds before you can pay.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w500),
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
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Setup Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantHeader(intent) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.storefront_rounded, color: Color(0xFF6366F1), size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          intent.merchantName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Verified LocalPay Merchant',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHeroAmount(quote) {
    final wallet = context.watch<WalletProvider>();
    final balance = wallet.tokenBalances[selectedToken] ?? 0.0;
    final hasSufficientFunds = balance >= quote.amountCrypto;

    return Column(
      children: [
        Text(
          '${quote.amountCrypto} ${quote.token}',
          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -1),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '≈ ${currencyFormat.format(context.watch<PaymentProvider>().currentIntent?.amountVnd ?? 0)}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasSufficientFunds ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Balance: ${balance.toStringAsFixed(selectedToken == 'SOL' ? 4 : 2)} $selectedToken',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hasSufficientFunds ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      ],
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
                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: Center(
                child: Text(
                  token,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuoteBreakdown(quote, bool isFetching) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _buildRow('Exchange Rate', '1 ${quote.token} = ${NumberFormat.compactSimpleCurrency(locale: 'vi_VN', name: '₫', decimalDigits: 0).format(quote.rate)}', isPending: isFetching),
          const SizedBox(height: 16),
          _buildRow('Service fee', 'Free', color: const Color(0xFF10B981)),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rate expires in', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Icon(Icons.timer_rounded, size: 16, color: _secondsRemaining < 5 ? Colors.redAccent : const Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Text(
                    '${_secondsRemaining}s',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _secondsRemaining < 5 ? Colors.redAccent : const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isPending = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Row(
          children: [
            if (isPending)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF94A3B8))),
              ),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? const Color(0xFF0F172A))),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceWarning(quote) {
    final wallet = context.watch<WalletProvider>();
    final balance = wallet.tokenBalances[selectedToken] ?? 0.0;
    final hasSufficientFunds = balance >= quote.amountCrypto;

    if (hasSufficientFunds) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insufficient Balance',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                ),
                Text(
                  'You need ${(quote.amountCrypto - balance).toStringAsFixed(selectedToken == 'SOL' ? 4 : 2)} more $selectedToken to complete this payment.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(provider, quote) {
    final isLoading = provider.step == PaymentStep.executing;
    final isQuoteExpired = _secondsRemaining <= 0;
    final wallet = context.watch<WalletProvider>();
    final balance = wallet.tokenBalances[selectedToken] ?? 0.0;
    final hasSufficientFunds = balance >= quote.amountCrypto;

    final isDisabled = isLoading || isQuoteExpired || !hasSufficientFunds;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isDisabled ? null : () async {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Text(
              isQuoteExpired 
                ? 'Refreshing Rate...' 
                : !hasSufficientFunds 
                  ? 'Insufficient Funds' 
                  : 'Pay with ${selectedToken}', 
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add a note',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          onChanged: (val) => context.read<PaymentProvider>().transactionDescription = val,
          decoration: InputDecoration(
            hintText: 'What is this for? (Optional)',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
          ),
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
