// © 2026 Project LostUAE

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/chat_pin_service.dart';
import 'unlock_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  final String caseId;
  final String? otherUserId; // optional — used to show "Chat with @username"

  const ChatScreen({super.key, required this.caseId, this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  String _otherUsername = '';

  @override
  void initState() {
    super.initState();
    _fetchOtherUsername();
  }

  /// Fetches the other participant's nickname.
  /// Uses [widget.otherUserId] if provided; otherwise resolves from the chat room document.
  Future<void> _fetchOtherUsername() async {
    String? targetId = widget.otherUserId;

    // Fallback: resolve from chat_rooms document
    if (targetId == null || targetId.isEmpty) {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.caseId)
          .get();
      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        final users = List<String>.from(data['users'] ?? []);
        targetId = users.firstWhere(
          (id) => id != user?.uid,
          orElse: () => '',
        );
      }
    }

    if (targetId == null || targetId.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .get();

    if (userDoc.exists && mounted) {
      final userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _otherUsername = userData['nickname'] ?? 'User';
      });
    }
  }

  // ─────────────────────────────────────────────
  // Navigate to unlock screen
  // ─────────────────────────────────────────────
  void _navigateToUnlock() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnlockChatScreen(caseId: widget.caseId),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Locked chat UI
  // ─────────────────────────────────────────────
  Widget _buildLockedChatUI() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _otherUsername.isNotEmpty ? 'Chat with @$_otherUsername' : 'Chat',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'This chat is locked',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need to verify your lost report to unlock this chat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToUnlock,
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Unlocked chat UI (original message UI — unchanged)
  // ─────────────────────────────────────────────
  Widget _buildUnlockedChatUI(bool isPinned) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _otherUsername.isNotEmpty
              ? 'Chat with @$_otherUsername'
              : 'Chat',
        ),
        actions: [
          IconButton(
            icon: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            tooltip: isPinned ? 'Unpin' : 'Pin to top',
            onPressed: () async {
              await ChatPinService.togglePin(widget.caseId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete chat',
            onPressed: () async {
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
                await ChatPinService.deleteChat(widget.caseId);
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.caseId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                        messages[index].data() as Map<String, dynamic>;

                    final isMe =
                        data['senderId'] == user!.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.green
                              : Colors.grey[300],
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: "Type message..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_controller.text.trim().isEmpty) return;

                    await FirebaseFirestore.instance
                        .collection('chat_rooms')
                        .doc(widget.caseId)
                        .collection('messages')
                        .add({
                      'senderId': user!.uid,
                      'text': _controller.text.trim(),
                      'timestamp':
                          FieldValue.serverTimestamp(),
                    });

                    await FirebaseFirestore.instance
                        .collection('chat_rooms')
                        .doc(widget.caseId)
                        .update({
                      'lastMessage': _controller.text.trim(),
                      'lastMessageTime':
                          FieldValue.serverTimestamp(),
                    });

                    _controller.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    // Outer StreamBuilder: listens to cases/{caseId} for lock status
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .snapshots(),
      builder: (context, caseSnap) {
        final caseData = caseSnap.data?.data() as Map<String, dynamic>?;
        final isLocked = caseData?['isLocked'] ?? true;

        if (isLocked) {
          return _buildLockedChatUI();
        }

        // Inner StreamBuilder: listens to chat_rooms/{caseId} for pin status
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(widget.caseId)
              .snapshots(),
          builder: (context, chatSnap) {
            final chatData = chatSnap.data?.data() as Map<String, dynamic>?;
            final isPinned = chatData != null && chatData['isPinned'] == true;

            return _buildUnlockedChatUI(isPinned);
          },
        );
      },
    );
  }
}
