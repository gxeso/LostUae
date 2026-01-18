import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsConsentScreenState();
}

class _TermsConsentScreenState extends State<TermsScreen> {
  bool agreed = false;
  bool loading = false;

  Future<void> _confirm() async {
    if (!agreed) return;

    setState(() => loading = true);

    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'hasAcceptedTerms': true,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          toggleTheme: () {},
          isDarkMode: false,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        automaticallyImplyLeading: false, // 🚫 NO BACK
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '''
Welcome to LostUAE.

By using this app you agree to:
• Provide truthful information
• Respect other users
• Not misuse the platform

LostUAE is not responsible for user interactions.
                  ''',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            CheckboxListTile(
              value: agreed,
              onChanged: (v) => setState(() => agreed = v ?? false),
              title: const Text('I agree to the Terms & Conditions'),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: agreed && !loading ? _confirm : null,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
