// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited


import 'package:flutter/material.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consent & Data')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '''
Consent & Data Usage

• You consent to storing your account data
• You consent to matching lost & found items
• You may withdraw consent by deleting your account

For any data requests, contact support@lostuae.app
          ''',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
