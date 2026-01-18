import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_passwordController.text.length < 8) {
      _error('Password must be at least 8 characters');
      return;
    }

    setState(() => _loading = true);

    try {
      await user.updatePassword(_passwordController.text.trim());

      // 🔒 FORCE LOGOUT AFTER PASSWORD CHANGE
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed. Please log in again.'),
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
      _error(e.message ?? 'Failed to update password');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(msg)),
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
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _changePassword,
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
