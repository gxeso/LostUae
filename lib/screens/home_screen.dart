// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';

import 'feed_screen.dart';
import 'post_item_screen.dart';
import 'profile_screen.dart';
import 'setting_screen.dart';
import 'my_posts_screen.dart';
import 'chat system/chat_list_screen.dart';

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
      const FeedScreen(), // 0
      const ChatListScreen(), // 1
      const MyPostsScreen(), // 2
      PostItemScreen( // 3
        onPostSuccess: () {
          setState(() => _currentIndex = 0);
        },
      ),
      ProfileScreen( // 4
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
    ];
  }

  AppBar _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_currentIndex) {
      case 0:
        return AppBar(
          title: const Text('LostUAE'),
          actions: const [NotificationBell()],
        );

      case 1:
        return AppBar(
          title: const Text('Chats'),
        );

      case 2:
        return AppBar(
          title: const Text('My Posts'),
        );

      case 3:
        return AppBar(
          title: const Text('Post Lost / Found Item'),
        );

      case 4:
        return AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              onPressed: widget.toggleTheme,
              icon: Icon(isDark ? Icons.wb_sunny : Icons.dark_mode),
            ),
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

      default:
        return AppBar(title: const Text('LostUAE'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor:
            theme.textTheme.bodySmall?.color?.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'My Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
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
