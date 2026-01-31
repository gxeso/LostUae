// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_item_screen.dart';
import 'package:lost_uae/CustomWidgets/empty_my_posts.dart';
import 'feed_screen.dart'; // for FeedItemCard

class MyPostsScreen extends StatelessWidget {
  final VoidCallback onCreatePost;

  const MyPostsScreen({
    super.key,
    required this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return EmptyMyPosts(
              onCreate: () {
                Navigator.pop(context); // back to profile
                onCreatePost(); // switch to Post tab
              },
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Column(
                children: [
                  // 🧩 REUSED FEED CARD
                  FeedItemCard(
                    itemId: doc.id,
                    userId: data['userId'],
                    status: data['status'],
                    isClaimed: data['isClaimed'] == true,
                    itemName: data['itemName'],
                    location:
                        data['locationName'] ?? data['location'] ?? '',
                    emirate: data['emirate'],
                    time: _formatTime(data['createdAt']),
                    imageUrl: data['imageUrl'],
                  ),

                  // ✏️ ACTION ROW
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditItemScreen(
                                  docId: doc.id,
                                  data: data,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('items')
                                .doc(doc.id)
                                .delete();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
