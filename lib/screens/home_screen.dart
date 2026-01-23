// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';

import 'feed_screen.dart';
import 'post_item_screen.dart';
import 'profile_screen.dart';
import 'setting_screen.dart';

import '../CustomWidgets/notification_bell.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const FeedScreen(),
      PostItemScreen(
        onPostSuccess: () {
          setState(() => _currentIndex = 0);
        },
      ),
      ProfileScreen(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
        onCreatePost: () {
          setState(() => _currentIndex = 1);
        },
      ),
    ];
  }

  AppBar _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 📰 FEED
    if (_currentIndex == 0) {
      return  AppBar(
        title: Text('LostUAE'),
        actions: const[
          NotificationBell(),
        ],
      );
    }

    // ➕ POST
    if (_currentIndex == 1) {
      return  AppBar(
        title: Text('Post Lost / Found Item'),
        automaticallyImplyLeading: false,
      );
    }

    // 👤 PROFILE
    return AppBar(
      title: const Text('Profile'),
      automaticallyImplyLeading: false,
      actions: [
        // 🌙 Dark / Light Mode
        IconButton(
          onPressed: widget.toggleTheme,
          icon: Icon(
            isDark ? Icons.wb_sunny : Icons.dark_mode,
            color: isDark ? Colors.yellow : Colors.white,
          ),
        ),

        // ⚙️ Settings
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
