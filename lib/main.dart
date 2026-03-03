import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:localpay_mobile/providers/auth_provider.dart';
import 'package:localpay_mobile/providers/payment_provider.dart';
import 'package:localpay_mobile/providers/wallet_provider.dart';
import 'package:localpay_mobile/main_navigation.dart';
import 'package:localpay_mobile/screens/onboarding_screen.dart';
import 'package:localpay_mobile/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Replace with your actual Supabase credentials
  await Supabase.initialize(
    url: 'https://wutntubiabgoalcvwhyu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind1dG50dWJpYWJnb2FsY3Z3aHl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0MzY3NjUsImV4cCI6MjA4ODAxMjc2NX0.OvZSUHLtwYU3aE-posaBotKoxj8rqJJ0-VwYsHQNpyU');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
          brightness: Brightness.light,
          primary: const Color(0xFF6366F1),
          surface: Colors.white,
          onSurface: const Color(0xFF0F172A),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: const Color(0xFF0F172A),
            displayColor: const Color(0xFF0F172A),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      home: Consumer2<AuthProvider, WalletProvider>(
        builder: (context, auth, wallet, child) {
          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }
          if (!wallet.hasWallet) {
            return const OnboardingScreen();
          }
          return const MainNavigation();
        },
      ),
    );
  }
}
