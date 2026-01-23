// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'item_details_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No notifications yet'),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(data['message'] ?? ''),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to open • Mark as read',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (data['createdAt'] != null)
                        Text(
                          _formatTime(data['createdAt']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),

                  // 👇 TAP NOTIFICATION
                  onTap: () => _handleNotificationTap(
                    context: context,
                    data: data,
                    docId: doc.id,
                  ),

                  // ✅ MARK AS READ BUTTON
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Mark as read',
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(doc.id)
                          .delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Handles tapping a notification
  Future<void> _handleNotificationTap({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String docId,
  }) async {
    final type = data['type'];

    // 🧹 Delete notification (mark as read)
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();

    // 🔔 MATCH → OPEN ITEM DETAILS WITH SIMILARITY
    if (type == 'match' && data['itemId'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItemDetailsScreen(
            itemId: data['itemId'],
            autoScrollToSimilarity: true,
          ),
        ),
      );
    }

    // ⏱️ POST LIMIT → no navigation
  }

  /// Formats Firestore timestamp → HH:mm
  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
