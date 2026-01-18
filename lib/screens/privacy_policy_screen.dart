import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Text(
            '''
LostUAE Privacy Policy

We collect only the information necessary to operate the platform:
- Email
- Phone number
- Lost & Found posts

Your data is never sold.
Your data is only used to help recover lost items.

You may request data deletion at any time.
            ''',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
