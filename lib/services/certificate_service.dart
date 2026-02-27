// © 2026 Project LostUAE

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import '../models/certificate_model.dart';
import '../models/lost_report_model.dart';
import 'mock_payment_service.dart';

/// Result returned after an unlock attempt.
class UnlockResult {
  final bool success;
  final String? certificateCode;
  final String? errorCode;
  final String? errorMessage;

  const UnlockResult({
    required this.success,
    this.certificateCode,
    this.errorCode,
    this.errorMessage,
  });

  factory UnlockResult.failure(String errorCode, String errorMessage) {
    return UnlockResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  factory UnlockResult.ok(String certificateCode) {
    return UnlockResult(success: true, certificateCode: certificateCode);
  }
}

class CertificateService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────
  // 1. Get current user's unlock count
  // ─────────────────────────────────────────────
  static Future<int> getUserUnlockCount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return 0;

    return (doc.data()?['unlockCount'] as int?) ?? 0;
  }

  // ─────────────────────────────────────────────
  // 2. Get current user's lost reports
  //    Queries the 'items' collection (status == 'Lost') since
  //    that is where user-posted lost items are stored.
  // ─────────────────────────────────────────────
  static Future<List<LostReportModel>> getUserLostReports() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snap = await _firestore
        .collection('items')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'Lost')
        .get();

    return snap.docs
        .map((doc) => LostReportModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  // ─────────────────────────────────────────────
  // 3. Get a single lost report by ID
  //    Reads from 'items' collection (where lost items live).
  // ─────────────────────────────────────────────
  static Future<LostReportModel?> getLostReport(String reportId) async {
    final doc = await _firestore.collection('items').doc(reportId).get();
    if (!doc.exists) return null;
    return LostReportModel.fromMap(doc.id, doc.data()!);
  }

  // ─────────────────────────────────────────────
  // 4. Get item category for a given case
  //    chat_rooms/{caseId} → itemId → items/{itemId} → category (or itemName)
  // ─────────────────────────────────────────────
  static Future<String?> getItemCategoryForCase(String caseId) async {
    final chatDoc =
        await _firestore.collection('chat_rooms').doc(caseId).get();
    if (!chatDoc.exists) return null;

    final itemId = chatDoc.data()?['itemId'] as String?;
    if (itemId == null || itemId.isEmpty) return null;

    final itemDoc = await _firestore.collection('items').doc(itemId).get();
    if (!itemDoc.exists) return null;

    final data = itemDoc.data()!;
    // Use explicit 'category' field if present; fall back to 'itemName'
    return (data['category'] as String?)?.isNotEmpty == true
        ? data['category'] as String
        : data['itemName'] as String?;
  }

  // ─────────────────────────────────────────────
  // 5. Check if a case chat is locked
  // ─────────────────────────────────────────────
  static Future<bool> isCaseLocked(String caseId) async {
    final doc = await _firestore.collection('cases').doc(caseId).get();
    if (!doc.exists) return true;
    return (doc.data()?['isLocked'] as bool?) ?? true;
  }

  // ─────────────────────────────────────────────
  // 6. Request chat unlock via Cloud Function
  //    Falls back to client-side unlock if the function
  //    is not yet deployed (not-found / NOT_FOUND).
  // ─────────────────────────────────────────────
  static Future<UnlockResult> requestChatUnlock({
    required String caseId,
    required String lostReportId,
  }) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('validateAndUnlockChat');

      final result = await callable.call<Map<String, dynamic>>({
        'caseId': caseId,
        'lostReportId': lostReportId,
      });

      final data = result.data;
      final certificateCode = data['certificateCode'] as String? ?? '';
      return UnlockResult.ok(certificateCode);
    } on FirebaseFunctionsException catch (e) {
      // Function not deployed yet → use client-side fallback
      if (e.code == 'not-found' ||
          (e.message?.toUpperCase() == 'NOT_FOUND')) {
        return _clientSideUnlock(
          caseId: caseId,
          lostReportId: lostReportId,
        );
      }
      return UnlockResult.failure(
        e.code,
        e.message ?? 'An error occurred during unlock.',
      );
    } catch (e) {
      return UnlockResult.failure(
        'unknown',
        e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────
  // 6b. Client-side fallback unlock
  //     Used when validateAndUnlockChat Cloud Function
  //     is not yet deployed. Performs basic ownership
  //     validation directly in Firestore.
  // ─────────────────────────────────────────────
  static Future<UnlockResult> _clientSideUnlock({
    required String caseId,
    required String lostReportId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return UnlockResult.failure('unauthenticated', 'Not signed in.');
    }

    try {
      // Verify the lost report exists and belongs to this user
      final reportDoc =
          await _firestore.collection('items').doc(lostReportId).get();
      if (!reportDoc.exists) {
        return UnlockResult.failure('not-found', 'Lost report not found.');
      }
      if (reportDoc.data()?['userId'] != uid) {
        return UnlockResult.failure(
            'permission-denied', 'This report does not belong to you.');
      }

      // Verify user is a participant in the chat room
      final chatDoc =
          await _firestore.collection('chat_rooms').doc(caseId).get();
      if (!chatDoc.exists) {
        return UnlockResult.failure('not-found', 'Chat room not found.');
      }
      final users = List<String>.from(chatDoc.data()?['users'] ?? []);
      if (!users.contains(uid)) {
        return UnlockResult.failure(
            'permission-denied', 'You are not a participant in this chat.');
      }

      // Generate a certificate code
      final rng = Random();
      final part1 = (1000 + rng.nextInt(9000)).toString();
      final part2 = (1000 + rng.nextInt(9000)).toString();
      final certificateCode = 'CERT-$part1-$part2';

      final now = Timestamp.now();
      final expiresAt = Timestamp.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch + 30 * 24 * 60 * 60 * 1000,
      );

      // Create certificate document
      await _firestore.collection('certificates').add({
        'certificateCode': certificateCode,
        'userId': uid,
        'lostReportId': lostReportId,
        'category': reportDoc.data()?['itemName'] ?? '',
        'issuedAt': now,
        'expiresAt': expiresAt,
        'boundThreadId': caseId,
        'status': 'active',
        'pdfPath': null,
      });

      // Unlock the case
      await _firestore.collection('cases').doc(caseId).update({
        'isLocked': false,
        'unlockedBy': uid,
        'unlockedAt': FieldValue.serverTimestamp(),
        'unlockedWithCertificate': certificateCode,
      });

      // Increment unlockCount (set to 1 if field doesn't exist)
      await _firestore.collection('users').doc(uid).set(
        {'unlockCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );

      // Log the unlock attempt
      await _firestore.collection('unlock_attempts').add({
        'userId': uid,
        'threadId': caseId,
        'certificateCode': certificateCode,
        'attemptedAt': now,
        'success': true,
        'failureReason': null,
      });

      return UnlockResult.ok(certificateCode);
    } catch (e) {
      return UnlockResult.failure('unknown', e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // 7. Get current user's certificates
  // ─────────────────────────────────────────────
  static Future<List<CertificateModel>> getUserCertificates() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snap = await _firestore
        .collection('certificates')
        .where('userId', isEqualTo: uid)
        .get();

    return snap.docs
        .map((doc) => CertificateModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  // ─────────────────────────────────────────────
  // 8. Process unlock with payment (if required)
  //    Handles payment gate before calling Cloud Function
  // ─────────────────────────────────────────────
  static Future<UnlockResult> processUnlockWithPayment({
    required String caseId,
    required String lostReportId,
    required int unlockCount,
  }) async {
    // If payment is required, process it first
    if (MockPaymentService.isPaymentRequired(unlockCount)) {
      final paid = await MockPaymentService.processPayment();
      if (!paid) {
        return UnlockResult.failure(
          'payment_failed',
          'Payment could not be processed. Please try again.',
        );
      }
    }

    // Call the Cloud Function to validate and unlock
    return requestChatUnlock(
      caseId: caseId,
      lostReportId: lostReportId,
    );
  }
}
