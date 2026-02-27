import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:localpay_mobile/models/payment_intent.dart';
import 'package:localpay_mobile/models/fx_quote.dart';
import 'package:localpay_mobile/models/payment_status.dart';

class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl}) 
    : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080/api/v1');

  Future<PaymentIntent> startPayment(String qrString) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'qr_string': qrString}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return PaymentIntent.fromJson(decoded['data']);
    } else {
      throw Exception('Failed to start payment: ${response.body}');
    }
  }

  Future<FxQuote> getQuote(String intentId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/quote'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'intent_id': intentId, 'token': token}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final intentJson = decoded['data'] as Map<String, dynamic>;
      final quoteJson = intentJson['quote'] as Map<String, dynamic>;
      return FxQuote.fromJson(quoteJson, token);
    } else {
      throw Exception('Failed to fetch quote: ${response.body}');
    }
  }

  Future<PaymentIntent> executePayment(String intentId, String userPublicKey) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'intent_id': intentId,
        'user_public_key': userPublicKey,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return PaymentIntent.fromJson(decoded['data']);
    } else {
      throw Exception('Failed to execute payment: ${response.body}');
    }
  }

  Future<PaymentStatus> checkStatus(String intentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/status/$intentId'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return PaymentStatus.fromJson(decoded['data']);
    } else {
      throw Exception('Failed to check status: ${response.body}');
    }
  }

  Future<void> simulateSuccess(String intentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/simulate-success/$intentId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to simulate success: ${response.body}');
    }
  }

  Future<String> requestAirdrop(String address) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/airdrop'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'address': address}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data']['signature'];
    } else {
      throw Exception('Airdrop failed: ${response.body}');
    }
  }

  Future<double> getBalance(String address) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/balance/$address'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded['data']['balance'] as num).toDouble();
    } else {
      throw Exception('Failed to get balance: ${response.body}');
    }
  }
}
