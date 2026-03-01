import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:localpay_mobile/providers/wallet_provider.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Scaffold(
      body: Stack(
        children: [
          // Mesh-like background
          _buildBackground(),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildBalanceSection(context, currencyFormat),
                  const SizedBox(height: 32),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                  _buildRecentActivity(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                ),
                child: const SizedBox.shrink(),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                ),
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
            ),
            const Text(
              'LocalPay User',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.2)),
              ),
              child: const Text(
                'DEVNET',
                style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceSection(BuildContext context, NumberFormat format) {
    final wallet = context.watch<WalletProvider>();
    // Mocking conversion for dashboard experience
    final solPriceVND = 2500000.0;
    final usdcPriceVND = 25400.0;
    
    final totalVND = (wallet.solBalance * solPriceVND) + 
                     ((wallet.tokenBalances['USDC'] ?? 0) * usdcPriceVND) +
                     ((wallet.tokenBalances['USDT'] ?? 0) * usdcPriceVND);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL BALANCE',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.remove_red_eye_outlined, size: 20, color: Colors.white.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            format.format(totalVND),
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTokenChip('SOL', wallet.solBalance, const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                _buildTokenChip('USDC', wallet.tokenBalances['USDC'] ?? 0, const Color(0xFF2775CA)),
                const SizedBox(width: 8),
                _buildTokenChip('USDT', wallet.tokenBalances['USDT'] ?? 0, const Color(0xFF26A17B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenChip(String symbol, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(width: 6),
          Text(
            amount.toStringAsFixed(amount < 1 ? 4 : 2),
            style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(context, 'Send', Icons.arrow_upward, const Color(0xFF6366F1)),
        _buildActionItem(context, 'Receive', Icons.arrow_downward, const Color(0xFF10B981)),
        _buildActionItem(context, 'Airdrop', Icons.bolt, const Color(0xFFF59E0B)),
        _buildActionItem(context, 'More', Icons.more_horiz, Colors.white38),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon, Color color) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (label == 'Airdrop') {
              context.read<WalletProvider>().requestAirdrop();
            }
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See All', style: TextStyle(color: Color(0xFF6366F1))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildActivityTile('Payment to Highlands Coffee', '- 45.000 ₫', 'Today, 2:45 PM', Icons.coffee, Colors.brown),
        _buildActivityTile('Airdrop Received', '+ 2.0 SOL', 'Yesterday, 10:15 AM', Icons.bolt, Colors.amber),
        _buildActivityTile('Payment to WinMart', '- 125.000 ₫', '24 Feb, 6:30 PM', Icons.shopping_bag, Colors.blue),
      ],
    );
  }

  Widget _buildActivityTile(String title, String amount, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amount.startsWith('+') ? const Color(0xFF10B981) : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
