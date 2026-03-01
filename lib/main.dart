import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localpay_mobile/main_navigation.dart';
import 'package:localpay_mobile/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:localpay_mobile/providers/payment_provider.dart';
import 'package:localpay_mobile/providers/wallet_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: const LocalPayApp(),
    ),
  );
}

class LocalPayApp extends StatelessWidget {
  const LocalPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalPay Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (!provider.hasWallet) {
            return const OnboardingScreen();
          }
          return const MainNavigation();
        },
      ),
    );
  }
}
