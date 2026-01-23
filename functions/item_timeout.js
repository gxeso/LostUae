exports.onItemCreatedUpdateUser = functions.firestore
  .document("items/{itemId}")
  .onCreate(async (snap) => {
    const item = snap.data();

    const userRef = admin.firestore()
      .collection("users")
      .doc(item.userId);

    await userRef.update({
      postCount: admin.firestore.FieldValue.increment(1),
      lastPostAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
