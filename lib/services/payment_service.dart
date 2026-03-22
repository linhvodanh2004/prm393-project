import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3000';

  Future<String> createPaymentLink({
    required String bookingId,
    required double amount,
    String returnUrl = 'app://staybook/return',
    String cancelUrl = 'app://staybook/cancel',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment/create-payment-link'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'bookingId': bookingId,
        'amount': amount.toInt(), // PayOS requires integer amount
        'returnUrl': returnUrl,
        'cancelUrl': cancelUrl,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return json['data']['checkoutUrl'];
      } else {
        throw Exception(json['message'] ?? 'Unknown error creating payment link');
      }
    } else {
      throw Exception('Failed to connect to payment server (status ${response.statusCode})');
    }
  }
}
