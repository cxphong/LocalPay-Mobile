import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:localpay_mobile/providers/wallet_provider.dart';

class WalletSetupScreen extends StatelessWidget {
  const WalletSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solana Wallet Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.hasWallet) {
            return _buildNoWalletView(context, provider);
          }

          return _buildWalletInfoView(context, provider);
        },
      ),
    );
  }

  Widget _buildNoWalletView(BuildContext context, WalletProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Color(0xFF6366F1)),
            const SizedBox(height: 32),
            const Text(
              'No Wallet Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create a new Solana wallet to start making payments on Devnet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => provider.createWallet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CREATE NEW WALLET', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletInfoView(BuildContext context, WalletProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddressCard(context, provider.address!),
          const SizedBox(height: 16),
          _buildMnemonicCard(context, provider.mnemonic!),
          const SizedBox(height: 32),
          _buildBalanceCard(provider),
          const SizedBox(height: 48),
          const Text(
            'Developer Tools',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(provider),
          const SizedBox(height: 48),
          Center(
            child: TextButton(
              onPressed: () => _showResetConfirmation(context, provider),
              child: const Text('RESET WALLET', style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, String address) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('WALLET ADDRESS', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2)),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Color(0xFF6366F1)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: address));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address copied to clipboard')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonicCard(BuildContext context, String mnemonic) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('WALLET MNEMONIC / PRIVATE KEY', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2)),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Color(0xFF6366F1)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: mnemonic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mnemonic copied to clipboard')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mnemonic,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.amberAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(WalletProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SOL BALANCE', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                provider.solBalance.toStringAsFixed(4),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Text('SOL', style: TextStyle(fontSize: 20, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(WalletProvider provider) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Airdrop 2 SOL'),
          subtitle: const Text('Free tokens on Devnet for testing'),
          trailing: const Icon(Icons.bolt, color: Colors.amber),
          onTap: () => provider.requestAirdrop(),
        ),
        const Divider(color: Colors.white10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Refresh Balance'),
          trailing: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
          onTap: () => provider.refreshBalance(),
        ),
      ],
    );
  }

  void _showResetConfirmation(BuildContext context, WalletProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Wallet?'),
        content: const Text('This will permanently delete your private key. Make sure you have a backup if you need it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.reset();
              Navigator.pop(context);
            },
            child: const Text('RESET', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
