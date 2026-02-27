// © 2026 Project LostUAE

class UnlockAttemptModel {
  final String attemptId;
  final String userId;
  final String threadId;
  final String certificateCode;
  final DateTime attemptedAt;
  final bool success;
  final String? failureReason;

  UnlockAttemptModel({
    required this.attemptId,
    required this.userId,
    required this.threadId,
    required this.certificateCode,
    required this.attemptedAt,
    required this.success,
    this.failureReason,
  });

  factory UnlockAttemptModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return UnlockAttemptModel(
      attemptId: id,
      userId: data['userId'] as String? ?? '',
      threadId: data['threadId'] as String? ?? '',
      certificateCode: data['certificateCode'] as String? ?? '',
      attemptedAt: parseTimestamp(data['attemptedAt']),
      success: data['success'] as bool? ?? false,
      failureReason: data['failureReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'threadId': threadId,
      'certificateCode': certificateCode,
      'attemptedAt': attemptedAt,
      'success': success,
      'failureReason': failureReason,
    };
  }
}
