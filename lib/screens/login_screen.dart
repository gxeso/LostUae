 // © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'sign_up_screen.dart';
import 'forget_pass_screen.dart';
import 'terms_screen.dart';
import 'utils/validators.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const LoginScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// 🔐 MAIN LOGIN HANDLER
  Future<bool> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 1️⃣ EMPTY CHECK
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return false;
    }

    // 2️⃣ EMAIL FORMAT CHECK
    if (!Validators.emailRegExp.hasMatch(email)) {
      _showError('Invalid email format');
      return false;
    }

    // 3️⃣ PASSWORD FORMAT CHECK
    if (!Validators.passwordRegExp.hasMatch(password)) {
      _showError(
        'Password must be at least 8 characters and contain letters and numbers',
      );
      return false;
    }

    try {
      // 4️⃣ FIREBASE AUTH
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _showError('Login failed. Try again.');
        return false;
      }

      // 5️⃣ TERMS & CONDITIONS CHECK (AFTER LOGIN)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final hasAccepted =
          userDoc.data()?['hasAcceptedTerms'] == true;

      if (!hasAccepted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TermsScreen(),
          ),
        );
        return false; // ⛔ BLOCK HOME
      }

      // 6️⃣ SUCCESS
      _showSuccess('Login successful');
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'No account found for this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }

      _showError(message);
      return false;
    }
  }

  /// ❌ ERROR SNACKBAR
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

  /// ✅ SUCCESS SNACKBAR
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text('LostUAE'),
        actions: [
          IconButton(
            onPressed: widget.toggleTheme,
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.dark_mode,
              color: isDark ? Colors.yellow : Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                'Login to your account',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              const Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 15),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  helperText: "We'll never share your email.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text('Password',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  helperText:
                      "At least 8 characters, with letters and numbers.",
                  helperMaxLines: 2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgetPassScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await _handleLogin();
                    if (!success) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(
                          toggleTheme: widget.toggleTheme,
                          isDarkMode: widget.isDarkMode,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Login'),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SignUpScreen(
                            toggleTheme: widget.toggleTheme,
                            isDarkMode: widget.isDarkMode,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
