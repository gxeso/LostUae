import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'passport_verification_screen.dart';


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
    builder: (_) => const PassportVerificationScreen(),
  ),
  (route) => false,
);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        automaticallyImplyLeading: false, // 🚫 no back
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Before you continue',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Please review and accept the terms below.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      '''
Welcome to LostUAE.

By using this application, you agree to:

• Provide accurate and truthful information  
• Respect other users and their property  
• Use the platform responsibly and lawfully  

LostUAE acts as a reporting platform and is not responsible for interactions between users.
                      ''',
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: agreed,
              onChanged: (v) => setState(() => agreed = v ?? false),
              title: const Text(
                'I agree to the Terms & Conditions',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: agreed && !loading ? _confirm : null,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
