// © 2026 Project LostUAE

class LostReportModel {
  final String reportId;
  final String userId;
  final String itemName;
  final String category;
  final String description;
  final String locationName;
  final String emirate;
  final DateTime createdAt;
  final String status;

  LostReportModel({
    required this.reportId,
    required this.userId,
    required this.itemName,
    required this.category,
    required this.description,
    required this.locationName,
    required this.emirate,
    required this.createdAt,
    required this.status,
  });

  factory LostReportModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    final itemName = data['itemName'] as String? ?? '';
    // Use explicit 'category' if present; fall back to 'itemName'
    // (items collection does not have a separate category field)
    final category = (data['category'] as String?)?.isNotEmpty == true
        ? data['category'] as String
        : itemName;

    return LostReportModel(
      reportId: id,
      userId: data['userId'] as String? ?? '',
      itemName: itemName,
      category: category,
      description: data['description'] as String? ?? '',
      locationName: data['locationName'] as String? ?? '',
      emirate: data['emirate'] as String? ?? '',
      createdAt: parseTimestamp(data['createdAt']),
      status: data['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'itemName': itemName,
      'category': category,
      'description': description,
      'locationName': locationName,
      'emirate': emirate,
      'createdAt': createdAt,
      'status': status,
    };
  }
}
