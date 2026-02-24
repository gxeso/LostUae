import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'chat system/chat_screen.dart';

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

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 1));

    final user = FirebaseAuth.instance.currentUser;

    // 🔥 NOT LOGGED IN
    if (user == null) {
      _goToLogin();
      return;
    }

    // 🔥 VERY IMPORTANT: CHECK IF FIRESTORE PROFILE EXISTS
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      // Ghost session detected
      await FirebaseAuth.instance.signOut();
      _goToLogin();
      return;
    }

    // 🔥 Deep link handling (chat)
    final initialRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;

    if (initialRoute.startsWith('lostuae://chat/')) {

      final targetUserId =
          initialRoute.replaceFirst('lostuae://chat/', '');

      if (user.uid != targetUserId) {

        final caseId = _generateCaseId(user.uid, targetUserId);

        final chatDoc = FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(caseId);

        final doc = await chatDoc.get();

        if (!doc.exists) {
          await chatDoc.set({
            'users': [user.uid, targetUserId],
            'isPinned': false, // ✅ REQUIRED for orderBy('isPinned') in chat list
            'lastMessage': '',
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(caseId: caseId),
          ),
        );

        return;
      }
    }

    // 🔥 Normal app open
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          toggleTheme: widget.toggleTheme,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  void _goToLogin() {
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

  String _generateCaseId(String a, String b) {
    return a.compareTo(b) < 0 ? "qr_${a}_$b" : "qr_${b}_$a";
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}