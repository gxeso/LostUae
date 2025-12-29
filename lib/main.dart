import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';


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

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      

      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // 🌞 LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color.fromARGB(255, 138, 72, 67),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 95, 24, 63),
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 220, 215, 215),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),

      // 🌙 DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color.fromARGB(255, 138, 72, 67),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),

      // ✅ CORRECT: home (NOT child)
      home: SplashScreen(
        toggleTheme: toggleTheme,
        isDarkMode: isDarkMode,
      ),
    );
  }
}
