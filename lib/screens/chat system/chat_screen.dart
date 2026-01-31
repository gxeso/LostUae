// © 2026 Project LostUAE
// Joint work – All rights reserved

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String caseId;

  const ChatScreen({super.key, required this.caseId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? otherUserName;
  bool loadingHeader = true;

  @override
  void initState() {
    super.initState();
    _loadChatHeader();
  }

  Future<void> _loadChatHeader() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final roomSnap = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.caseId)
        .get();

    if (!roomSnap.exists) return;

    final data = roomSnap.data()!;
    final otherUserId =
        data['lostUserId'] == currentUser.uid
            ? data['foundUserId']
            : data['lostUserId'];

    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .get();

    setState(() {
      otherUserName = userSnap.data()?['nickname'] ?? 'User';
      loadingHeader = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: loadingHeader
            ? const Text('Chat')
            : Text('Chat with @$otherUserName'),
      ),
      body: Column(
        children: [
          /// 💬 MESSAGES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.caseId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet'),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                        messages[index].data() as Map<String, dynamic>;

                    final isMe =
                        msg['senderId'] == currentUser.uid;

                    return _ChatBubble(
                      text: msg['text'] ?? '',
                      timestamp: msg['timestamp'],
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          /// ✍️ INPUT BAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color:
                          Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;

                      await sendMessage(
                        caseId: widget.caseId,
                        senderId: currentUser.uid,
                        text: text,
                      );

                      _controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================================================================== */
/*                               CHAT BUBBLE                                  */
/* ========================================================================== */

class _ChatBubble extends StatelessWidget {
  final String text;
  final Timestamp? timestamp;
  final bool isMe;

  const _ChatBubble({
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade200;

    final textColor = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                Radius.circular(isMe ? 16 : 4),
            bottomRight:
                Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white70
                    : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
