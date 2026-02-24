import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'screens/splash_screen.dart';
import 'screens/qr system/public_profile_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      // ✅ FIX: correct method name
      final Uri? uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleUri(uri);
      }

      // Listen for background / foreground links
      _sub = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _handleUri(uri);
        },
        onError: (err) {
          debugPrint("Deep link error: $err");
        },
      );
    } catch (e) {
      debugPrint("Deep link init error: $e");
    }
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == "lostuae" &&
        uri.host == "profile" &&
        uri.pathSegments.isNotEmpty) {

      final userId = uri.pathSegments.first;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(userId: userId),
        ),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(
        toggleTheme: toggleTheme,
        isDarkMode: isDarkMode,
      ),
    );
  }
}