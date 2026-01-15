// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited


import 'package:flutter/material.dart';
import 'utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';




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
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

 void _handleSignUp() async {
  final nickname = nicknameController.text.trim();
  final email = emailController.text.trim();
  final phone = phoneController.text.trim();
  final password = passwordController.text.trim();
  final confirmPassword = confirmPasswordController.text.trim();

  // 1️⃣ Empty check
  if (nickname.isEmpty ||
      email.isEmpty ||
      phone.isEmpty ||
      password.isEmpty ||
      confirmPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all fields')),
    );
    return;
  }

  // 2️⃣ Nickname regex
  if (!Validators.nicknameRegex.hasMatch(nickname)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nickname must be 3–15 letters or numbers'),
      ),
    );
    return;
  }

  // 3️⃣ Email regex
  if (!Validators.emailRegExp.hasMatch(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid email format')),
    );
    return;
  }

  // 4️⃣ UAE phone regex
  if (!Validators.uaePhoneRegex.hasMatch(phone)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid UAE phone number')),
    );
    return;
  }

  // 5️⃣ Password regex
  if (!Validators.passwordRegExp.hasMatch(password)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password must be at least 8 characters and include letters and numbers',
        ),
      ),
    );
    return;
  }

  // 6️⃣ Password match
  if (password != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passwords do not match')),
    );
    return;
  }

  try {
    // 7️⃣ CREATE AUTH USER
    final credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    final uid = user.uid;

    // 8️⃣ STORE USER PROFILE IN FIRESTORE 🔥
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'phone': phone,
      'role': 'user',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 9️⃣ SUCCESS
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Account created successfully'),
      ),
    );

    Navigator.pop(context); // Back to login

  } on FirebaseAuthException catch (e) {
    String message = 'Sign up failed';

    if (e.code == 'email-already-in-use') {
      message = 'This email is already registered';
    } else if (e.code == 'invalid-email') {
      message = 'Invalid email address';
    } else if (e.code == 'weak-password') {
      message = 'Password is too weak';
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
  title: const Text('Create Account'),
  
),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Join LostUAE',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new account',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // Nickname
              const Text('Nickname', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: nicknameController,
                decoration: InputDecoration(
                  hintText: 'Enter your nickname',
                  helperText: "3–15 letters or numbers, no spaces.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Email
              const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  helperText: "We'll use this for account recovery only.",
                  helperMaxLines: 2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Phone
              const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+971 5X XXX XXXX',
                  helperText: "UAE numbers only (starts with +971 or 05).",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password
              const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Create a strong password',
                  helperText: "At least 8 characters, with uppercase, lowercase, and a number.",
                  helperMaxLines: 2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Password
              const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Repeat your password',
                  helperText: "Must match the password above.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 18),
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
