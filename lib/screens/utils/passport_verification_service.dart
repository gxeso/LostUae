import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class PassportVerificationService {
  static const _endpoint =
      'https://id-passport-ai-4991329968.us-central1.run.app/verify-passport';

  static Future<Map<String, dynamic>> verifyPassport(File image) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        // Optional but recommended for future auth hardening
        'Authorization': 'Bearer ${await user.getIdToken()}',
      },
      body: jsonEncode({
        'imageBase64': base64Image,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Verification failed');
    }

    return jsonDecode(response.body);
  }
}
