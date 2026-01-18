import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() => _loading = true);

    try {
      // 1️⃣ Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // 2️⃣ Delete Firestore user profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // 3️⃣ Delete user items
      final items = await FirebaseFirestore.instance
          .collection('items')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in items.docs) {
        await doc.reference.delete();
      }

      // 4️⃣ Delete Firebase Auth account
      await user.delete();

      // 5️⃣ Sign out
      await FirebaseAuth.instance.signOut();

      // 6️⃣ Force navigation to Login
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            toggleTheme: () {},
            isDarkMode: false,
          ),
        ),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Account deletion failed';

      if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please log in again and retry';
      }

      _showError(message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ This action is permanent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Deleting your account will permanently remove your data. This action cannot be undone.',
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: _loading ? null : _deleteAccount,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Delete My Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
