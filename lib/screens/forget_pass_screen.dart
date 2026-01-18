// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited


import 'package:flutter/material.dart';
import 'utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ForgetPassScreen extends StatefulWidget {
  

  const ForgetPassScreen({
    super.key
  });

  @override
  State<ForgetPassScreen> createState() => _ForgetPassScreenState();
}

class _ForgetPassScreenState extends State<ForgetPassScreen> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _handleEmail() async {
  final email = emailController.text.trim();

  // 1️⃣ Empty check
  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter your email')),
    );
    return;
  }

  // 2️⃣ Email regex
  if (!Validators.emailRegExp.hasMatch(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid email format')),
    );
    return;
  }

  try {
    // 3️⃣ Firebase password reset
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    // 4️⃣ Success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('Password reset email sent to $email'),
      ),
    );

    Navigator.pop(context); // Back to login

  } on FirebaseAuthException catch (e) {
    String message = 'Something went wrong';

    if (e.code == 'user-not-found') {
      message = 'No account found for this email';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Password'),
        iconTheme: IconThemeData(color: Colors.white),
        
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Enter your email to recover your password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  helperText: "We'll send you a recovery link.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleEmail,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Send Recovery Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
