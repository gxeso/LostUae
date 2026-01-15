// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),

        // ✅ FORCE BACK ICON COLOR
        iconTheme: const IconThemeData(
          color: Colors.white, // ⬅️ always white
        ),
      ),

      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notifications yet',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    return ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(data['title'] ?? 'Notification'),
                      subtitle: Text(data['body'] ?? ''),
                    );
                  },
                );
              },
            ),
    );
  }
}
