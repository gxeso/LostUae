import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationListener {
  static void start(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        _showNotificationPopup(context, doc);
      }
    });
  }

  static void _showNotificationPopup(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(data['title'] ?? 'Notification'),
        content: Text(data['message'] ?? ''),
        actions: [
          TextButton(
            onPressed: () async {
              // ✅ MARK AS READ = DELETE
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(doc.id)
                  .delete();

              Navigator.pop(context);
            },
            child: const Text('Mark as read'),
          ),
        ],
      ),
    );
  }
}
