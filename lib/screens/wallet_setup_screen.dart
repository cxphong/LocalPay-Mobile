import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:localpay_mobile/providers/wallet_provider.dart';

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
      body: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: !provider.hasWallet
                      ? _buildNoWalletView(context, provider)
                      : _buildWalletInfoView(context, provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Wallet',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your keys and funds',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
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
              const Text('RECOVERY PHRASE', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2)),
              if (_isMnemonicVisible)
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
          const SizedBox(height: 16),
          if (!_isMnemonicVisible)
            GestureDetector(
              onTap: () => setState(() => _isMnemonicVisible = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFF6366F1)),
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
                Text(
                  mnemonic,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.amberAccent),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => setState(() => _isMnemonicVisible = false),
                  icon: const Icon(Icons.visibility_off_outlined, size: 16, color: Colors.white38),
                  label: const Text('Hide phrase', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(WalletProvider provider) {
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
          const Text('ASSETS', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          _buildBalanceRow('SOL', provider.solBalance, const Color(0xFF6366F1)),
          const Divider(height: 32, color: Colors.white10),
          _buildBalanceRow('USDC', provider.tokenBalances['USDC'] ?? 0, const Color(0xFF2775CA)),
          const Divider(height: 32, color: Colors.white10),
          _buildBalanceRow('USDT', provider.tokenBalances['USDT'] ?? 0, const Color(0xFF26A17B)),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(String symbol, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  symbol[0],
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              symbol,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          amount.toStringAsFixed(amount < 1 ? 4 : 2),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Refresh Balance'),
          trailing: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
          onTap: () => provider.refreshBalance(),
        ),
        const Divider(color: Colors.white10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fund Server Wallet'),
          subtitle: const Text('Airdrop SOL to Backend Fee Payer'),
          trailing: const Icon(Icons.storage, color: Colors.blueAccent),
          onTap: () => provider.fundServerWallet(),
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
