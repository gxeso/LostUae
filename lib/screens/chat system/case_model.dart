class CaseModel {
  final String caseId;
  final String lostUserId;
  final String foundUserId;
  final bool lostUserConfirmed;
  final bool foundUserConfirmed;
  final String status;

  // ── Unlock fields ──
  final bool isLocked;
  final String? unlockedBy;
  final DateTime? unlockedAt;
  final String? unlockedWithCertificate;

  CaseModel({
    required this.caseId,
    required this.lostUserId,
    required this.foundUserId,
    required this.lostUserConfirmed,
    required this.foundUserConfirmed,
    required this.status,
    this.isLocked = true,
    this.unlockedBy,
    this.unlockedAt,
    this.unlockedWithCertificate,
  });

  /// Returns true if the given [userId] is a participant in this case.
  bool isParticipant(String userId) {
    return userId == lostUserId || userId == foundUserId;
  }

  /// Chat is accessible only when the case is not locked.
  bool get isChatAccessible => !isLocked;

  factory CaseModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return CaseModel(
      caseId: id,
      lostUserId: data['lostUserId'] as String? ?? '',
      foundUserId: data['foundUserId'] as String? ?? '',
      lostUserConfirmed: data['lostUserConfirmed'] as bool? ?? false,
      foundUserConfirmed: data['foundUserConfirmed'] as bool? ?? false,
      status: data['status'] as String? ?? 'active',
      isLocked: data['isLocked'] as bool? ?? true,
      unlockedBy: data['unlockedBy'] as String?,
      unlockedAt: parseTimestamp(data['unlockedAt']),
      unlockedWithCertificate: data['unlockedWithCertificate'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lostUserId': lostUserId,
      'foundUserId': foundUserId,
      'lostUserConfirmed': lostUserConfirmed,
      'foundUserConfirmed': foundUserConfirmed,
      'status': status,
      'isLocked': isLocked,
      'unlockedBy': unlockedBy,
      'unlockedAt': unlockedAt,
      'unlockedWithCertificate': unlockedWithCertificate,
    };
  }
}
