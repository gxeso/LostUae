// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'home_screen.dart';
import 'sign_up_screen.dart';
import 'forget_pass_screen.dart';
import 'terms_screen.dart';
import 'complete_profile_screen.dart';
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /* ================= EMAIL LOGIN ================= */
  Future<void> _handleEmailLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    if (!Validators.emailRegExp.hasMatch(email)) {
      _showError('Invalid email format');
      return;
    }

    if (!Validators.passwordRegExp.hasMatch(password)) {
      _showError('Password must contain letters & numbers');
      return;
    }

    try {
      setState(() => isLoading = true);

      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = cred.user;
      if (user == null) {
        _showError('Login failed');
        return;
      }

      await _checkTermsAndNavigate(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showError('No account found');
      } else if (e.code == 'wrong-password') {
        _showError('Incorrect password');
      } else {
        _showError('Login failed');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  /* ================= GOOGLE LOGIN ================= */
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => isLoading = true);

      // 1️⃣ Google sign in
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 2️⃣ Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) return;

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // 3️⃣ Create Firestore doc if first time
      final snap = await userRef.get();
      if (!snap.exists) {
        await userRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'createdAt': Timestamp.now(),
          'postCount': 0,
          'lastPostAt': Timestamp.fromMillisecondsSinceEpoch(0),
          'hasAcceptedTerms': false,
          'termsAcceptedAt': null,
        });
      }

      final data = (await userRef.get()).data();

      // 4️⃣ PROFILE COMPLETION CHECK
      final nickname = data?['nickname'] as String?;
final phone = data?['phone'] as String?;

final needsProfile =
    nickname == null ||
    nickname.trim().isEmpty ||
    phone == null ||
    phone.trim().isEmpty;


      if (needsProfile) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CompleteProfileScreen(),
          ),
        );
        return;
      }

      // 5️⃣ TERMS CHECK
      final hasAcceptedTerms = data?['hasAcceptedTerms'] == true;
      if (!hasAcceptedTerms) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TermsScreen()),
        );
        return;
      }

      // 6️⃣ HOME
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            toggleTheme: widget.toggleTheme,
            isDarkMode: widget.isDarkMode,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      debugPrint('🔥 GOOGLE LOGIN ERROR: $e');
      _showError('Google sign-in failed');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /* ================= TERMS CHECK ================= */
  Future<void> _checkTermsAndNavigate(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final hasAccepted = doc.data()?['hasAcceptedTerms'] == true;

    if (!hasAccepted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TermsScreen()),
      );
      return;
    }

    _showSuccess('Login successful');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          toggleTheme: widget.toggleTheme,
          isDarkMode: widget.isDarkMode,
        ),
      ),
      (_) => false,
    );
  }

  /* ================= UI HELPERS ================= */
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(msg)),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.green, content: Text(msg)),
    );
  }

  /* ================= UI ================= */
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LostUAE'),
        centerTitle: true,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Login to your account',
                style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 40),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgetPassScreen()),
                ),
                child: const Text('Forgot password?'),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleEmailLogin,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continue with Google'),
                onPressed: isLoading ? null : _handleGoogleSignIn,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignUpScreen(
                        toggleTheme: widget.toggleTheme,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  ),
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
    );
  }
}
