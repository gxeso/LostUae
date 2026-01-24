class CaseModel {
  final String caseId;
  final String lostUserId;
  final String foundUserId;
  final bool lostUserConfirmed;
  final bool foundUserConfirmed;
  final String status;

  CaseModel({
    required this.caseId,
    required this.lostUserId,
    required this.foundUserId,
    required this.lostUserConfirmed,
    required this.foundUserConfirmed,
    required this.status,
  });

  factory CaseModel.fromMap(String id, Map<String, dynamic> data) {
    return CaseModel(
      caseId: id,
      lostUserId: data['lostUserId'] as String,
      foundUserId: data['foundUserId'] as String,
      lostUserConfirmed: data['lostUserConfirmed'] as bool,
      foundUserConfirmed: data['foundUserConfirmed'] as bool,
      status: data['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lostUserId': lostUserId,
      'foundUserId': foundUserId,


      'lostUserConfirmed': lostUserConfirmed,
      'foundUserConfirmed': foundUserConfirmed,

      'status': status,
    };
  }
}