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
import '../theme/app_colors.dart';

// ONLY showing changed + important parts (keep rest same)

class LoginScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  // 🔥 ADD THIS
  final bool autoDeleteAfterLogin;

  const LoginScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    this.autoDeleteAfterLogin = false, // 🔥 default
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

  try {
    setState(() => isLoading = true);

    final cred = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    final user = cred.user;
    if (user == null) return;

    // 🔥 AUTO DELETE AFTER LOGIN
    if (widget.autoDeleteAfterLogin) {
      try {
        final uid = user.uid;

        // 1. DELETE AUTH
        await user.delete();

        // 2. DELETE FIRESTORE DATA
        final firestore = FirebaseFirestore.instance;

        final items = await firestore
            .collection('items')
            .where('userId', isEqualTo: uid)
            .get();

        for (final doc in items.docs) {
          await doc.reference.delete();
        }

        final notis = await firestore
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .get();

        for (final doc in notis.docs) {
          await doc.reference.delete();
        }

        await firestore.collection('users').doc(uid).delete();

        // 3. SIGN OUT
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Account deleted successfully'),
          ),
        );

        return;
      } catch (e) {
        print("AUTO DELETE ERROR: $e");
        _showError('Delete failed after login');
        return;
      }
    }

    // NORMAL FLOW
    await _checkTermsAndNavigate(user);

  } catch (e) {
    _showError('Login failed');
  } finally {
    setState(() => isLoading = false);
  }
}
  /* ================= GOOGLE LOGIN ================= */
Future<void> _handleGoogleSignIn() async {
  try {
    setState(() => isLoading = true);

    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    // Required in v7+
    await googleSignIn.initialize(
      serverClientId: null,
    );

    await googleSignIn.signOut();

    final GoogleSignInAccount account =
        await googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth =
        await account.authentication;

    final OAuthCredential credential =
        GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCredential.user;
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snap = await userRef.get();

    if (!snap.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'nickname': '',
        'phone': '',
        'createdAt': Timestamp.now(),
        'postCount': 0,
        'lastPostAt': Timestamp.fromMillisecondsSinceEpoch(0),
        'hasAcceptedTerms': false,
        'termsAcceptedAt': null,
        'role': 'guest',
        'accountStatus': 'active',   // ✅ default — changed to 'investigated' after 3+ reports
        'pendingReportCount': 0,     // ✅ incremented by ReportService on each report
      });
    }

    final data = (await userRef.get()).data();

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

    final hasAcceptedTerms = data?['hasAcceptedTerms'] == true;

    if (!hasAcceptedTerms) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TermsScreen()),
      );
      return;
    }

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
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(msg),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(msg),
      ),
    );
  }

  /* ================= UI ================= */
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LostUAE'),
        actions: [
          IconButton(
            onPressed: widget.toggleTheme,
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.dark_mode,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            Text(
              'Welcome Back',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Login to your account',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 40),

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
              label: 'Password text field',
              textField: true,
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                ),
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgetPassScreen(),
                  ),
                ),
                child: const Text('Forgot password?'),
              ),
            ),

            const SizedBox(height: 24),

            Semantics(
              label: isLoading ? 'Logging in, please wait' : 'Login to your account',
              button: true,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleEmailLogin,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Login'),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Semantics(
              label: 'Continue with Google',
              button: true,
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Continue with Google'),
                  onPressed: isLoading ? null : _handleGoogleSignIn,
                ),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                Semantics(
                  label: 'Sign up for a new account',
                  button: true,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignUpScreen(
                          toggleTheme: widget.toggleTheme,
                          isDarkMode: widget.isDarkMode,
                        ),
                      ),
                    ),
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
