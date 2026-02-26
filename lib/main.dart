import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/qr system/public_profile_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

/// Global notifier for Color Blind Mode.
/// Updated by AccessibilitySettingsScreen; listened to in MyApp.build().
final ValueNotifier<bool> colorBlindModeNotifier = ValueNotifier<bool>(false);

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
  bool _largeTextEnabled = false;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
    _loadLargeTextSetting();
  }

  Future<void> _loadLargeTextSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _largeTextEnabled = prefs.getBool('largeTextEnabled') ?? false;
    });
    // Load Color Blind Mode into the global notifier (no setState needed –
    // ValueNotifier triggers its own listeners).
    colorBlindModeNotifier.value = prefs.getBool('colorBlindMode') ?? false;
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
    return ValueListenableBuilder<bool>(
      valueListenable: colorBlindModeNotifier,
      builder: (context, isColorBlind, _) {
        final app = MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: _largeTextEnabled
                    ? const TextScaler.linear(1.3)
                    : TextScaler.noScaling,
              ),
              child: child!,
            );
          },
          home: SplashScreen(
            toggleTheme: toggleTheme,
            isDarkMode: isDarkMode,
          ),
        );

        if (isColorBlind) {
          // Protanopia-safe color matrix (Machado et al. 2009).
          // Shifts red/green channels to improve distinguishability
          // without altering layout, theme, or any widget design.
          return ColorFiltered(
            colorFilter: ColorFilter.matrix(<double>[
              0.567, 0.433, 0,     0, 0,
              0.558, 0.442, 0,     0, 0,
              0,     0.242, 0.758, 0, 0,
              0,     0,     0,     1, 0,
            ]),
            child: app,
          );
        }

        return app;
      },
    );
  }
}