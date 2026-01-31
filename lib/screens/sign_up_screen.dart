// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'utils/validators.dart';
import '../theme/app_colors.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SignUpScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /* =========================
     🔍 UNIQUENESS CHECKS
     ========================= */

  Future<bool> _exists(String field, String value) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where(field, isEqualTo: value)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /* =========================
     🚀 SIGN UP
     ========================= */

  Future<void> _handleSignUp() async {
  if (isLoading) return;

  final nickname = nicknameController.text.trim();
  final email = emailController.text.trim();
  final phone = phoneController.text.trim();
  final password = passwordController.text.trim();
  final confirmPassword = confirmPasswordController.text.trim();

  if ([nickname, email, phone, password, confirmPassword]
      .any((e) => e.isEmpty)) {
    _showError('Please fill in all fields');
    return;
  }

  if (!Validators.nicknameRegex.hasMatch(nickname)) {
    _showError('Nickname must be 3–15 letters or numbers');
    return;
  }

  if (!Validators.emailRegExp.hasMatch(email)) {
    _showError('Invalid email format');
    return;
  }

  if (!Validators.uaePhoneRegex.hasMatch(phone)) {
    _showError('Invalid UAE phone number');
    return;
  }

  if (!Validators.passwordRegExp.hasMatch(password)) {
    _showError('Weak password');
    return;
  }

  if (password != confirmPassword) {
    _showError('Passwords do not match');
    return;
  }

  setState(() => isLoading = true);

  try {
    // 🔍 UNIQUENESS CHECKS
    if (await _exists('nickname', nickname)) {
      _showError('Nickname already taken');
      return;
    }
    if (await _exists('email', email)) {
      _showError('Email already in use');
      return;
    }
    if (await _exists('phone', phone)) {
      _showError('Phone number already in use');
      return;
    }

    // 🔐 AUTH
    final credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // 👤 FIRESTORE PROFILE
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'nickname': nickname,
      'email': email,
      'phone': phone,

      // ACCESS CONTROL
      'role': 'guest',
      'verificationStatus': 'none',
      'hasAcceptedTerms': false,

      // META
      'createdAt': Timestamp.now(),
      'postCount': 0,
      'lastPostAt': Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Account created successfully'),
      ),
    );

    Navigator.pop(context);
  } catch (e) {
    _showError('Account creation failed. Try again.');
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}


  /* =========================
     ❌ ERROR UI
     ========================= */

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(message),
      ),
    );
  }

  /* =========================
     🖥 UI
     ========================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Join LostUAE',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new account',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),

              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  helperText: 'Unique · 3–15 letters or numbers',
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  helperText: 'UAE only (05xxxxxxxx)',
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSignUp,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
