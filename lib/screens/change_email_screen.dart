// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited



import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _changeEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      await user.verifyBeforeUpdateEmail(
        _emailController.text.trim(),
      );

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification email sent. Please confirm and log in again.',
            ),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              toggleTheme: () {},
              isDarkMode: false,
            ),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _changeEmail,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm & Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
