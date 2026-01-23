// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

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
  bool _loading = false;

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is permanent.\n\n'
          'All your posts, matches, and data will be permanently deleted.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      // 1️⃣ Delete user items
      final items = await firestore
          .collection('items')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in items.docs) {
        await doc.reference.delete();
      }

      // 2️⃣ Delete notifications
      final notis = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in notis.docs) {
        await doc.reference.delete();
      }

      // 3️⃣ Delete user profile
      await firestore.collection('users').doc(uid).delete();

      // 4️⃣ Delete Firebase Auth account
      await user.delete();

      // 5️⃣ Sign out
      await FirebaseAuth.instance.signOut();

      // 6️⃣ Navigate to Login
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

    if (e.code == 'requires-recent-login') {
  await FirebaseAuth.instance.signOut();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.orange,
      content: Text(
        'Please log in again to confirm account deletion.',
        style: TextStyle(color: Colors.white),
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
    (_) => false,
  );
  return;
}


      _showError(message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Deleting your account will permanently remove:\n'
              '• Your profile\n'
              '• All your posts\n'
              '• Matches & notifications\n\n'
              'This action cannot be undone.',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _loading ? null : _confirmAndDelete,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Delete My Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
