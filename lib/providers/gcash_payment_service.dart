import 'dart:convert';
import 'package:http/http.dart' as http;

class GCashPaymentService {
  static const String backendUrl = 'https://capstone.x10.mx/create-payment';

  static Future<String> getPaymentUrl({
    required String uid,
    required int amountInCentavos,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'amount': amountInCentavos,
          'type': 'gcash',
        }),
      );

      final Map<String, dynamic> jsonBody = jsonDecode(response.body);
      print('🔄 GCash Response: $jsonBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonBody.containsKey('checkout_url')) {
          return jsonBody['checkout_url'];
        }

        // 🔍 Check nested structure: details > data > attributes > redirect > checkout_url
        final nestedUrl = jsonBody['details']?['data']?['attributes']
            ?['redirect']?['checkout_url'];
        if (nestedUrl != null && nestedUrl.toString().isNotEmpty) {
          return nestedUrl;
        }

        // Optional: fallback if the full 'data' exists at the root
        final altUrl =
            jsonBody['data']?['attributes']?['redirect']?['checkout_url'];
        if (altUrl != null && altUrl.toString().isNotEmpty) {
          return altUrl;
        }

        throw Exception(
          '❌ No valid checkout URL found in any known structure.',
        );
      } else {
        final errorMsg =
            jsonBody['error'] ?? jsonBody['message'] ?? 'Unknown error';
        throw Exception(
          '❌ GCash API error: ${response.statusCode} - $errorMsg',
        );
      }
    } catch (e) {
      print('❌ GCash exception: $e');
      rethrow;
    }
  }
}
