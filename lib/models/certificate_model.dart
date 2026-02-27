// © 2026 Project LostUAE

enum CertificateStatus { active, expired, used }

class CertificateModel {
  final String certificateId;
  final String certificateCode;
  final String userId;
  final String lostReportId;
  final String category;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String? boundThreadId;
  final CertificateStatus status;
  final String? pdfPath;

  CertificateModel({
    required this.certificateId,
    required this.certificateCode,
    required this.userId,
    required this.lostReportId,
    required this.category,
    required this.issuedAt,
    required this.expiresAt,
    this.boundThreadId,
    required this.status,
    this.pdfPath,
  });

  /// Whether the certificate is currently valid (active and not expired).
  bool get isValid => status == CertificateStatus.active && !isExpired;

  /// Whether the certificate has passed its expiry date.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory CertificateModel.fromMap(String id, Map<String, dynamic> data) {
    CertificateStatus parseStatus(String? s) {
      switch (s) {
        case 'expired':
          return CertificateStatus.expired;
        case 'used':
          return CertificateStatus.used;
        default:
          return CertificateStatus.active;
      }
    }

    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      // Firestore Timestamp
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return CertificateModel(
      certificateId: id,
      certificateCode: data['certificateCode'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      lostReportId: data['lostReportId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      issuedAt: parseTimestamp(data['issuedAt']),
      expiresAt: parseTimestamp(data['expiresAt']),
      boundThreadId: data['boundThreadId'] as String?,
      status: parseStatus(data['status'] as String?),
      pdfPath: data['pdfPath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    String statusString() {
      switch (status) {
        case CertificateStatus.expired:
          return 'expired';
        case CertificateStatus.used:
          return 'used';
        case CertificateStatus.active:
          return 'active';
      }
    }

    return {
      'certificateCode': certificateCode,
      'userId': userId,
      'lostReportId': lostReportId,
      'category': category,
      'issuedAt': issuedAt,
      'expiresAt': expiresAt,
      'boundThreadId': boundThreadId,
      'status': statusString(),
      'pdfPath': pdfPath,
    };
  }
}
