// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  final user = FirebaseAuth.instance.currentUser;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('users', arrayContains: user!.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No chats yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final chats = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = chats[index];
            final data = doc.data() as Map<String, dynamic>;
            final caseId = doc.id;

            final lastMessage =
                (data['lastMessage'] ?? '').toString();
            final itemId = data['itemId'];

            // 🔥 FETCH ITEM NAME SAFELY
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('items')
                  .doc(itemId)
                  .get(),
              builder: (context, itemSnap) {
                String title = 'Item Chat';

                if (itemSnap.hasData && itemSnap.data!.exists) {
                  final itemData =
                      itemSnap.data!.data() as Map<String, dynamic>;
                  title = itemData['itemName'] ?? title;
                }

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.green,
                    ),
                  ),

                  // ✅ ITEM NAME (NOT ID)
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  subtitle: Text(
                    lastMessage.isNotEmpty
                        ? lastMessage
                        : 'Tap to open chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.grey),
                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(caseId: caseId),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
