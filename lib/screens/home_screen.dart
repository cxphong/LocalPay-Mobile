import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:localpay_mobile/providers/wallet_provider.dart';
import 'package:intl/intl.dart';
import 'package:localpay_mobile/screens/deposit_screen.dart';
import 'package:localpay_mobile/screens/withdraw_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => context.read<WalletProvider>().refreshBalance(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildBalanceSection(context, currencyFormat),
                    const SizedBox(height: 32),
                    _buildQuickActions(context),
                    const SizedBox(height: 40),
                    _buildRecentActivity(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'LP',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning,',
                  style: TextStyle(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Text(
                  'LocalPay User',
                  style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'DEVNET',
                style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            _buildHeaderIcon(Icons.notifications_none_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Icon(icon, color: const Color(0xFF0F172A), size: 22),
    );
  }

  Widget _buildBalanceSection(BuildContext context, NumberFormat format) {
    final wallet = context.watch<WalletProvider>();
    final solPriceVND = 2500000.0;
    final usdcPriceVND = 25400.0;
    
    final totalVND = (wallet.solBalance * solPriceVND) + 
                     ((wallet.tokenBalances['USDC'] ?? 0) * usdcPriceVND) +
                     ((wallet.tokenBalances['USDT'] ?? 0) * usdcPriceVND);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Keep one dark "premium" element
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withOpacity(0.3)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            format.format(totalVND),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAssetInfo('SOL', wallet.solBalance, Icons.account_balance_wallet_rounded),
              _buildAssetInfo('USDC', wallet.tokenBalances['USDC'] ?? 0, Icons.monetization_on_rounded),
              _buildAssetInfo('USDT', wallet.tokenBalances['USDT'] ?? 0, Icons.currency_exchange_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetInfo(String label, double amount, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: const Color(0xFF6366F1)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          amount.toStringAsFixed(amount < 1 ? 3 : 2),
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(context, 'Send', Icons.arrow_upward_rounded, const Color(0xFF6366F1)),
        _buildActionItem(context, 'Receive', Icons.arrow_downward_rounded, const Color(0xFF10B981)),
        _buildActionItem(context, 'Scan QR', Icons.qr_code_scanner_rounded, const Color(0xFF0F172A)),
        _buildActionItem(context, 'More', Icons.grid_view_rounded, const Color(0xFF64748B)),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon, Color color) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (label == 'Send') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen()));
            } else if (label == 'Receive') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DepositScreen()));
            }
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final transactions = wallet.transactions;
    final timeFormat = DateFormat('MMM dd, hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transactions',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => wallet.fetchHistory(),
              child: const Text('Refresh', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Icon(Icons.history_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        else
          ...transactions.take(5).map((tx) {
            final isNegative = true; // For now all payments are out
            final symbol = tx.token == 'SOL' ? 'SOL' : '₫';
            final amountStr = isNegative 
              ? '- ${tx.amountVnd > 0 ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(tx.amountVnd) : tx.amountUsdt.toStringAsFixed(2) + " " + tx.token}'
              : '+ ${tx.amountVnd > 0 ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(tx.amountVnd) : tx.amountUsdt.toStringAsFixed(2) + " " + tx.token}';
            
            return _buildActivityTile(
              tx.description,
              amountStr,
              timeFormat.format(tx.createdAt),
              tx.token == 'SOL' ? Icons.account_balance_wallet_rounded : Icons.monetization_on_rounded,
              tx.status == 'COMPLETED' ? Colors.green : Colors.orange,
            );
          }),
      ],
    );
  }

  Widget _buildActivityTile(String title, String amount, String time, IconData icon, Color color) {
    final isPositive = amount.startsWith('+');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? const Color(0xFF10B981) : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
