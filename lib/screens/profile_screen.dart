// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_posts_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onCreatePost;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const ProfileScreen({
    super.key,
    required this.onCreatePost,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User profile not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 👤 Avatar
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, size: 55, color: Colors.white),
                ),

                const SizedBox(height: 16),

                // Nickname
                Text(
                  data['nickname'] ?? 'No nickname',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                _infoTile('Email', data['email'] ?? ''),
                _infoTile('User ID', user.uid),
                _infoTile('Phone', data['phone'] ?? 'Not provided'),

                const SizedBox(height: 30),

                // 📦 My Posts
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

                // 🚪 Logout
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
          );
        },
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
