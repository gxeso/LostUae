// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';
import '../../services/chat_pin_service.dart';

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

        // Sort in Dart: pinned first, then by lastMessageTime (already ordered by Firestore).
        // Doing this in Dart avoids a composite index requirement and handles legacy
        // documents that were created before the isPinned field was added.
        final chats = [...snapshot.data!.docs]..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aPinned = aData['isPinned'] == true ? 1 : 0;
            final bPinned = bData['isPinned'] == true ? 1 : 0;
            return bPinned.compareTo(aPinned);
          });

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
            final isPinned = data['isPinned'] == true;

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
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Icon(
                      isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
                      color: Colors.green,
                    ),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    lastMessage.isNotEmpty ? lastMessage : 'Tap to open chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Resolve the other participant's ID from the users array
                    final users = List<String>.from(data['users'] ?? []);
                    final otherUserId = users.firstWhere(
                      (id) => id != user!.uid,
                      orElse: () => '',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          caseId: caseId,
                          otherUserId: otherUserId,
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(
                              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            ),
                            title: Text(isPinned ? 'Unpin' : 'Pin to top'),
                            onTap: () async {
                              Navigator.pop(context);
                              await ChatPinService.togglePin(caseId);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text('Delete', style: TextStyle(color: Colors.red)),
                            onTap: () async {
                              Navigator.pop(context);
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Chat'),
                                  content: const Text('Are you sure you want to delete this chat?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ChatPinService.deleteChat(caseId);
                              }
                            },
                          ),
                        ],
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
