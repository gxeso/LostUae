// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  static const int reportThreshold = 3;

  /// Check if a user can report a specific item (user cannot report their own item)
  static Future<bool> canReport(String itemId, String ownerId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    if (currentUser.uid == ownerId) return false;
    return true;
  }

  /// Check if user has already reported this item
  static Future<bool> hasAlreadyReported(String itemId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final existingReport = await FirebaseFirestore.instance
        .collection('reports')
        .where('itemId', isEqualTo: itemId)
        .where('reporterId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    return existingReport.docs.isNotEmpty;
  }

  /// Submit a report for an item
  static Future<bool> submitReport({
    required String itemId,
    required String ownerId,
    required String reportType,
    required String description,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    // Verify user cannot report their own item
    if (currentUser.uid == ownerId) return false;

    // Check if already reported
    if (await hasAlreadyReported(itemId)) return false;

    try {
      // Add report to reports collection
      await FirebaseFirestore.instance.collection('reports').add({
        'itemId': itemId,
        'ownerId': ownerId,
        'reporterId': currentUser.uid,
        'reportType': reportType,
        'description': description,
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });

      // Check report count for this owner and update status if needed
      await _checkAndUpdateUserStatus(ownerId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Atomically increment pendingReportCount on the user document.
  /// If the count reaches the threshold, also set accountStatus = 'investigated'.
  /// Uses a transaction so the read + write are atomic and avoids querying
  /// the reports collection (which would require broader read permissions).
  static Future<void> _checkAndUpdateUserStatus(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>;
      final currentCount = (data['pendingReportCount'] as num?)?.toInt() ?? 0;
      final newCount = currentCount + 1;

      final updates = <String, dynamic>{'pendingReportCount': newCount};
      if (newCount >= reportThreshold) {
        updates['accountStatus'] = 'investigated';
      }

      transaction.update(userRef, updates);
    });
  }

  /// Get user account status
  static Future<String?> getUserAccountStatus(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!userDoc.exists) return null;

    final data = userDoc.data() as Map<String, dynamic>;
    return data['accountStatus'] as String?;
  }

  /// Check if user can post (not investigated)
  static Future<bool> canPost(String userId) async {
    final status = await getUserAccountStatus(userId);
    return status != 'investigated';
  }

  /// Check if user can chat (not investigated)
  static Future<bool> canChat(String userId) async {
    final status = await getUserAccountStatus(userId);
    return status != 'investigated';
  }
}
