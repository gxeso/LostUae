/**
 * Cloud Functions – STABLE VERSION
 * - Create user document on Auth signup (Email / Google)
 * - Similarity matching
 * - Post rate limit + notification
 * - Reset post limits
 * - Cleanup claimed items
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/* =====================================================
   👤 CREATE USER DOC ON AUTH SIGNUP (EMAIL + GOOGLE)
   ===================================================== */
exports.onAuthUserCreated = functions.auth.user().onCreate(async (user) => {
  const userRef = db.collection("users").doc(user.uid);
  const snap = await userRef.get();

  if (snap.exists) return;

  await userRef.set({
    uid: user.uid,
    email: user.email ?? "",
    nickname: user.displayName ?? "User",
    phone: user.phoneNumber ?? "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    postCount: 0,
    lastPostAt: admin.firestore.Timestamp.fromMillis(0),
    hasAcceptedTerms: false,
    termsAcceptedAt: null,
  });
});

/* =====================================================
   🔗 SIMILARITY MATCHING
   ===================================================== */
exports.onItemCreated = functions.firestore
  .document("items/{itemId}")
  .onCreate(async (snap, context) => {
    const newItem = snap.data();
    const newItemId = context.params.itemId;

    if (!newItem?.description) return;

    const items = await db.collection("items").get();
    const batch = db.batch();

    items.forEach((doc) => {
      if (doc.id === newItemId) return;
      const other = doc.data();
      if (!other?.description) return;
      if (other.status === newItem.status) return;

      const score = 0.5; // placeholder – your similarity fn here

      if (score < 0.3) return;

      const sourceId = newItemId < doc.id ? newItemId : doc.id;
      const targetId = newItemId < doc.id ? doc.id : newItemId;

      batch.set(
        db.collection("matched").doc(`${sourceId}__${targetId}`),
        {
          sourceId,
          targetId,
          score,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    await batch.commit();
  });

/* =====================================================
   ⏱️ POST LIMIT + NOTIFICATION
   ===================================================== */
exports.onItemCreatedUpdateUser = functions.firestore
  .document("items/{itemId}")
  .onCreate(async (snap) => {
    const item = snap.data();
    if (!item?.userId) return;

    const userRef = db.collection("users").doc(item.userId);

    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) return;

      const count = (userSnap.data().postCount ?? 0) + 1;
      const now = admin.firestore.Timestamp.now();

      tx.update(userRef, {
        postCount: count,
        lastPostAt: now,
      });

      if (count === 3) {
        tx.set(db.collection("notifications").doc(), {
          userId: item.userId,
          type: "post_limit",
          message:
            "You’ve reached the posting limit. Please wait 10 minutes before posting again.",
          isRead: false,
          cooldownUntil: admin.firestore.Timestamp.fromMillis(
            now.toMillis() + 10 * 60 * 1000
          ),
          createdAt: now,
        });
      }
    });
  });

/* =====================================================
   🧹 CLEANUP CLAIMED ITEMS (DAILY)
   ===================================================== */
exports.cleanupClaimedItems = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const cutoff = admin.firestore.Timestamp.fromMillis(
      Date.now() - 7 * 24 * 60 * 60 * 1000
    );

    const snap = await db
      .collection("items")
      .where("isClaimed", "==", true)
      .where("claimedAt", "<=", cutoff)
      .get();

    const batch = db.batch();
    snap.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  });
  

/* =====================================================
   🔔 NOTIFY USERS WHEN A MATCH IS CREATED
   ===================================================== */
exports.onMatchCreated = functions.firestore
  .document("matched/{matchId}")
  .onCreate(async (snap, context) => {
    const match = snap.data();
    if (!match) return;

    const { sourceId, targetId } = match;

    const [sourceSnap, targetSnap] = await Promise.all([
      db.collection("items").doc(sourceId).get(),
      db.collection("items").doc(targetId).get(),
    ]);

    if (!sourceSnap.exists || !targetSnap.exists) return;

    const sourceItem = sourceSnap.data();
    const targetItem = targetSnap.data();

    if (!sourceItem?.userId || !targetItem?.userId) return;

    const batch = db.batch();

    // 🔔 Notify source user
    batch.set(db.collection("notifications").doc(), {
      userId: sourceItem.userId,
      type: "match",
      title: "Possible match found 👀",
      message: "One of your items has a potential match.",
      itemId: sourceId,
      matchId: context.params.matchId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 🔔 Notify target user
    batch.set(db.collection("notifications").doc(), {
      userId: targetItem.userId,
      type: "match",
      title: "Possible match found 👀",
      message: "One of your items has a potential match.",
      itemId: targetId,
      matchId: context.params.matchId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();
  });
