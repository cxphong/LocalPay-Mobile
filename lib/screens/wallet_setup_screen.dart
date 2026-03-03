import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:localpay_mobile/providers/wallet_provider.dart';
import 'package:localpay_mobile/providers/auth_provider.dart';

class WalletSetupScreen extends StatefulWidget {
  const WalletSetupScreen({super.key});

  @override
  State<WalletSetupScreen> createState() => _WalletSetupScreenState();
}

class _WalletSetupScreenState extends State<WalletSetupScreen> {
  bool _isMnemonicVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Wallet Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: !provider.hasWallet
                ? _buildNoWalletView(context, provider)
                : _buildWalletInfoView(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildNoWalletView(BuildContext context, WalletProvider provider) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 32),
          const Text(
            'Secure Your Digital Assets',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create a new Solana wallet to start managing your funds and making instant payments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => provider.createWallet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Create New Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletInfoView(BuildContext context, WalletProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Security & Keys'),
          _buildAddressCard(context, provider.address!),
          const SizedBox(height: 16),
          _buildMnemonicCard(context, provider.mnemonic!),
          const SizedBox(height: 32),
          _buildSectionHeader('Assets'),
          _buildBalanceCard(provider),
          const SizedBox(height: 32),
          _buildSectionHeader('Developer Tools'),
          _buildActionButtons(provider),
          const SizedBox(height: 48),
          Center(
            child: TextButton.icon(
              onPressed: () => _showResetConfirmation(context, provider),
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              label: const Text('Reset Wallet Data', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, String address) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SOLANA ADDRESS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: address));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                },
                child: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF6366F1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonicCard(BuildContext context, String mnemonic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECOVERY PHRASE', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (!_isMnemonicVisible)
            GestureDetector(
              onTap: () => setState(() => _isMnemonicVisible = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFF6366F1), size: 28),
                    const SizedBox(height: 8),
                    const Text('Tap to Reveal', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    mnemonic,
                    style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Color(0xFF92400E), fontWeight: FontWeight.w600, height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _isMnemonicVisible = false),
                      icon: const Icon(Icons.visibility_off_rounded, size: 16, color: Color(0xFF94A3B8)),
                      label: const Text('Hide Phrase', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: mnemonic));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF6366F1)),
                      label: const Text('Copy All', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(WalletProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildBalanceItem('SOL', provider.solBalance, const Color(0xFF6366F1)),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          _buildBalanceItem('USDC', provider.tokenBalances['USDC'] ?? 0, const Color(0xFF2775CA)),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          _buildBalanceItem('USDT', provider.tokenBalances['USDT'] ?? 0, const Color(0xFF26A17B)),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String symbol, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text(symbol[0], style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const Spacer(),
          Text(
            amount.toStringAsFixed(amount < 1 ? 4 : 2),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(WalletProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildToolTile('Airdrop 1.0 SOL', 'Testing tokens', Icons.bolt_rounded, Colors.amber, () => provider.requestAirdrop()),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          _buildToolTile('Refresh Balances', 'Force update', Icons.refresh_rounded, const Color(0xFF6366F1), () => provider.refreshBalance()),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          _buildToolTile('Fund Fee Payer', 'Internal transfer', Icons.lan_rounded, Colors.blueAccent, () => provider.fundServerWallet()),
        ],
      ),
    );
  }

  Widget _buildToolTile(String title, String sub, IconData icon, Color color, VoidCallback tap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
      onTap: tap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  void _showResetConfirmation(BuildContext context, WalletProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Wallet?'),
        content: const Text('This will delete your local keys. You can only recover them with your recovery phrase.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () { provider.reset(); Navigator.pop(context); },
            child: const Text('RESET', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
