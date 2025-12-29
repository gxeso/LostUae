import 'package:flutter/material.dart';
import 'package:lost_uae/screens/home_screen.dart';
import 'sign_up_screen.dart';
import 'forget_pass_screen.dart';
import 'utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
    // Always dispose controllers
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  // 1️⃣ Empty check
  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter email and password')),
    );
    return;
  }

  // 2️⃣ Email format check (REGEX)
  if (!Validators.emailRegExp.hasMatch(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid email format')),
    );
    return;
  }

  // 3️⃣ Password format check (REGEX)
  if (!Validators.passwordRegExp.hasMatch(password)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password must be at least 8 characters and contain letters and numbers',
        ),
      ),
    );
    return;
  }

  try {
    // 4️⃣ Firebase login (REAL AUTH)
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 5️⃣ Success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Login successful'),
      ),
    );

  } on FirebaseAuthException catch (e) {
    String message = 'Login failed';

    if (e.code == 'user-not-found') {
      message = 'No account found for this email';
    } else if (e.code == 'wrong-password') {
      message = 'Incorrect password';
    } else if (e.code == 'invalid-email') {
      message = 'Invalid email address';
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
  centerTitle: true,
  elevation: 0,
  title: const Text('LostUAE'),
  actions: [
    IconButton(
      onPressed: widget.toggleTheme,
      icon: Icon(
        widget.isDarkMode ? Icons.wb_sunny : Icons.dark_mode,
        color: widget.isDarkMode ? Colors.yellow : Colors.white,
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
              SizedBox(height: 20),
              // Title
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Login to your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // Email
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
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

              // Password
              const Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Create a strong password.',
                  helperText: "At least 8 characters, with uppercase, lowercase, and a number.",
                  helperMaxLines: 2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navigate to forget password screen
                    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ForgetPassScreen(
      toggleTheme: widget.toggleTheme,
      isDarkMode: widget.isDarkMode,
    ),
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

              // Login button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    
                    _handleLogin();

                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(
                      toggleTheme: widget.toggleTheme,
                      isDarkMode: widget.isDarkMode,
                    ),),);

                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Login'),
                ),
              ),

              const SizedBox(height: 24),

              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SignUpScreen(
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
 