// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPinService {
  /// Toggle pin status for a chat room
  static Future<void> togglePin(String caseId) async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(caseId)
        .get();

    if (!chatDoc.exists) return;

    final data = chatDoc.data() as Map<String, dynamic>;
    final currentPinStatus = data['isPinned'] == true;

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(caseId)
        .update({
      'isPinned': !currentPinStatus,
    });
  }

  /// Delete a chat room
  static Future<void> deleteChat(String caseId) async {
    // Delete all messages in the chat room
    final messages = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(caseId)
        .collection('messages')
        .get();

    // Delete each message
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }

    // Delete the chat room itself
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(caseId)
        .delete();
  }

  /// Check if a chat is pinned
  static Future<bool> isPinned(String caseId) async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(caseId)
        .get();

    if (!chatDoc.exists) return false;

    final data = chatDoc.data() as Map<String, dynamic>;
    return data['isPinned'] == true;
  }
}
