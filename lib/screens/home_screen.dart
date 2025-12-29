import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'post_item_screen.dart';
import 'profile_screen.dart';

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
          setState(() {
            _currentIndex = 0; // 🔥 GO BACK TO FEED
          });
        },
      ),

      ProfileScreen(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
        onCreatePost: () {
          setState(() {
            _currentIndex = 1; // 🔥 SWITCH TO POST TAB
          });
        },
      ),
    ];
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        _currentIndex == 1 ? 'Post Lost / Found Item' : 'LostUAE',
      ),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(
            widget.isDarkMode ? Icons.wb_sunny : Icons.dark_mode,
            color: widget.isDarkMode ? Colors.yellow : Colors.white,
          ),
          onPressed: widget.toggleTheme,
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
