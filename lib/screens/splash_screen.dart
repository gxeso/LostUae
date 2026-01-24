// © 2026 Project Name
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SplashScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 🎬 Background animation (slow, continuous)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // 🎞 Fade-in for content
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    // ⏳ Splash delay + auth check
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              toggleTheme: widget.toggleTheme,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              toggleTheme: widget.toggleTheme,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              // 🌿 ANIMATED GREEN GRADIENT
              gradient: LinearGradient(
                begin: Alignment(0, -1 + (_controller.value * 0.3)),
                end: Alignment(0, 1 + (_controller.value * 0.3)),
                colors: const [
                  Color(0xFF0F3D2E), // deep green
                  Color(0xFF0A2A20), // darker base
                ],
              ),
            ),
            child: child,
          );
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✨ LOGO WITH GREEN GLOW (TRANSPARENT PNG)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2ECC71).withOpacity(0.25),
                        blurRadius: 60,
                        spreadRadius: 18,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/LostUAE_LOGO.png',
                    width: 160,
                    height: 160,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'LostUAE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'National Lost & Found Service',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
