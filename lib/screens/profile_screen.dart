import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_posts_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final VoidCallback onCreatePost;

  const ProfileScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 👤 Avatar
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[300],
                child: const Icon(
                  Icons.person,
                  size: 55,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              _infoTile('Email', user.email ?? 'Not available'),
              _infoTile('User ID', user.uid),
              _infoTile('Phone', user.phoneNumber ?? 'Not provided'),

              const SizedBox(height: 30),

              // 📦 MY POSTS
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('My Posts'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyPostsScreen(
                          onCreatePost: onCreatePost,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(),

              // 🚪 LOGOUT
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(
                          toggleTheme: toggleTheme,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
