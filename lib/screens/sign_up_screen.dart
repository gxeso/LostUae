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

  UserCredential? credential;

  try {
    // 🔥 STEP 1: CREATE AUTH USER FIRST
    credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      _showError('Account creation failed');
      return;
    }

    final uid = user.uid;

    // 🔥 STEP 2: NOW USER IS AUTHENTICATED → QUERY ALLOWED
    final nicknameExists = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .limit(1)
        .get();

    if (nicknameExists.docs.isNotEmpty) {
      await user.delete();
      _showError('Nickname already taken');
      return;
    }

    final phoneExists = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (phoneExists.docs.isNotEmpty) {
      await user.delete();
      _showError('Phone already in use');
      return;
    }

    // 🔥 STEP 3: CREATE FIRESTORE PROFILE
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'nickname': nickname,
      'email': email,
      'phone': phone,
      'role': 'guest',
      'verificationStatus': 'none',
      'hasAcceptedTerms': false,
      'createdAt': Timestamp.now(),
      'postCount': 0,
      'lastPostAt': Timestamp.now(),
      'accountStatus': 'active',   // ✅ default — changed to 'investigated' after 3+ reports
      'pendingReportCount': 0,     // ✅ incremented by ReportService on each report
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Account created successfully'),
      ),
    );

    Navigator.pop(context);

  } on FirebaseAuthException catch (e) {

    if (e.code == 'email-already-in-use') {
      _showError('Email already in use');
    } else if (e.code == 'weak-password') {
      _showError('Weak password');
    } else {
      _showError('Account creation failed');
    }

  } catch (e) {
    _showError('Something went wrong');
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
              Text(
                'Join LostUAE',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new account',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),

              Semantics(
                label: 'Nickname text field',
                textField: true,
                child: TextField(
                  controller: nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    hintText: 'Choose a unique username (3–15 characters)',
                    helperText: 'Unique · 3–15 letters or numbers',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Semantics(
                label: 'Email text field',
                textField: true,
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Semantics(
                label: 'Phone Number text field',
                textField: true,
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter UAE mobile number (05XXXXXXXX)',
                    helperText: 'UAE only (05xxxxxxxx)',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Semantics(
                label: 'Password text field',
                textField: true,
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Create a strong password (letters and numbers)',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Semantics(
                label: 'Confirm Password text field',
                textField: true,
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Semantics(
                label: isLoading ? 'Creating account, please wait' : 'Create new account',
                button: true,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSignUp,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Account'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
