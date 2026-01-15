// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited



import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String? itemId,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'itemId': itemId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markAsRead(String docId) async {
    await _db.collection('notifications').doc(docId).update({
      'isRead': true,
    });
  }
}
