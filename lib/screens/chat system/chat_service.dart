import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createCaseAndChat({
  required String caseId,
  required String lostUserId,
  required String foundUserId,
  required String itemId,
  required String itemName,
}) async {
  final firestore = FirebaseFirestore.instance;

  // ✅ CREATE CASE — only if it doesn't already exist (preserves existing data)
  // Wrapped in try-catch: Firestore denies reads on non-existent documents when
  // the rule checks resource.data (null for missing docs). PERMISSION_DENIED here
  // means the doc doesn't exist yet — safe to create.
  final caseRef = firestore.collection('cases').doc(caseId);
  bool caseExists = false;
  try {
    final caseDoc = await caseRef.get();
    caseExists = caseDoc.exists;
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      caseExists = false; // doc doesn't exist
    } else {
      rethrow;
    }
  }
  if (!caseExists) {
    await caseRef.set({
      'lostUserId': lostUserId,
      'foundUserId': foundUserId,
      'lostUserConfirmed': false,
      'foundUserConfirmed': false,
      'status': 'active',
      'isLocked': true,
      'createdAt': Timestamp.now(),
    });
  }

  // ✅ CREATE CHAT ROOM — only if it doesn't already exist (preserves chat history)
  final chatRef = firestore.collection('chat_rooms').doc(caseId);
  bool chatExists = false;
  try {
    final chatDoc = await chatRef.get();
    chatExists = chatDoc.exists;
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      chatExists = false; // doc doesn't exist
    } else {
      rethrow;
    }
  }
  if (!chatExists) {
    await chatRef.set({
      'users': [lostUserId, foundUserId],
      'itemId': itemId,
      'itemName': itemName,
      'isClosed': false,
      'isPinned': false, // ✅ REQUIRED for orderBy('isPinned') in chat list
      'lastMessage': '',
      'lastMessageTime': Timestamp.now(),
    });
  }
}

Stream<QuerySnapshot> getActiveChats(String userId) {
  return FirebaseFirestore.instance
      .collection('chat_rooms')
      .where('users', arrayContains: userId)
      .orderBy('lastMessageTime', descending: true)
      .snapshots();
}

Future<void> sendMessage({
  required String caseId,
  required String senderId,
  required String text,
}) async {
  final chatRef =
      FirebaseFirestore.instance.collection('chat_rooms').doc(caseId);

  await chatRef.collection('messages').add({
    'senderId': senderId,
    'text': text,
    'timestamp': Timestamp.now(),
    'type': 'text',
  });

  await chatRef.update({
    'lastMessage': text,
    'lastMessageTime': Timestamp.now(),
  });
}
