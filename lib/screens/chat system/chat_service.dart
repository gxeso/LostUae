import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createCaseAndChat({
  required String caseId,
  required String lostUserId,
  required String foundUserId,
  required String itemId,
  required String itemName,
}) async {
  final firestore = FirebaseFirestore.instance;

  // ✅ CREATE CASE (NO READS)
  await firestore.collection('cases').doc(caseId).set({
    'lostUserId': lostUserId,
    'foundUserId': foundUserId,
    'lostUserConfirmed': false,
    'foundUserConfirmed': false,
    'status': 'active',
    'createdAt': Timestamp.now(),
  });

  // ✅ CREATE CHAT ROOM (NO READS)
  await firestore.collection('chat_rooms').doc(caseId).set({
  'users': [lostUserId, foundUserId],
  'itemId': itemId,
  'itemName': itemName, // ✅ STORE IT
  'isClosed': false,
  'lastMessage': '',
  'lastMessageTime': Timestamp.now(),
});

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
