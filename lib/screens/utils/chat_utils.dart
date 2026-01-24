// Generates a deterministic caseId so chats are never duplicated
String buildCaseId(String itemId, String userA, String userB) {
  final users = [userA, userB]..sort();
  return '${itemId}_${users[0]}_${users[1]}';
}
