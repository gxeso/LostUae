// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_item_screen.dart';
import 'post_item_screen.dart';
import 'package:lost_uae/CustomWidgets/empty_my_posts.dart';
import 'feed_screen.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ FIXED: pass onCreate
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return EmptyMyPosts(
            onCreate: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostItemScreen(
                    onPostSuccess: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
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

            final bool isClaimed = data['isClaimed'] == true;

            return Column(
              children: [
                FeedItemCard(
                  itemId: doc.id,
                  userId: data['userId'],
                  status: data['status'],
                  isClaimed: isClaimed,
                  itemName: data['itemName'],
                  location:
                      data['locationName'] ?? data['location'] ?? '',
                  emirate: data['emirate'],
                  time: _formatTime(data['createdAt']),
                  imageUrl: data['imageUrl'],
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isClaimed) ...[
                      const Icon(Icons.lock, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text(
                        "Claimed",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
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
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark as Claimed'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('items')
                              .doc(doc.id)
                              .update({
                            'isClaimed': true,
                            'status': 'claimed',
                          });
                        },
                      ),
                      const SizedBox(width: 8),

                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('items')
                              .doc(doc.id)
                              .delete();
                        },
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
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
