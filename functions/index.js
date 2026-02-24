/**
 * LostUAE Cloud Functions – Production Version
 * ---------------------------------------------
 * ✔ Create user document on Auth signup
 * ✔ Real similarity matching (hybrid Jaccard model)
 * ✔ Post rate limit + notification
 * ✔ Daily cleanup of claimed items
 * ✔ Match notifications
 * ✔ Account investigation notification
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { calculateSimilarity } = require("./similarity");

admin.initializeApp();
const db = admin.firestore();

/* =====================================================
   👤 CREATE USER DOC ON AUTH SIGNUP
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
   🔗 REAL SIMILARITY MATCHING
   ===================================================== */
exports.onItemCreated = functions.firestore
  .document("items/{itemId}")
  .onCreate(async (snap, context) => {
    const newItem = snap.data();
    const newItemId = context.params.itemId;

    if (!newItem?.description || !newItem?.status) return;

    // Only fetch items with the OPPOSITE status (Lost ↔ Found).
    // This avoids a full collection scan and cuts read costs significantly.
    const oppositeStatus = newItem.status === "Lost" ? "Found" : "Lost";

    let itemsSnapshot;
    try {
      itemsSnapshot = await db
        .collection("items")
        .where("status", "==", oppositeStatus)
        .get();
    } catch (err) {
      console.error("onItemCreated: failed to fetch opposite items", err);
      return;
    }

    const batch = db.batch();

    for (const doc of itemsSnapshot.docs) {
      if (doc.id === newItemId) continue;

      const other = doc.data();
      if (!other?.description) continue;

      const score = calculateSimilarity(
        newItem.description,
        other.description
      );

      // Threshold: 0.30 — calibrated for the hybrid stopword-aware model.
      if (score < 0.30) continue;

      const sourceId = newItemId < doc.id ? newItemId : doc.id;
      const targetId = newItemId < doc.id ? doc.id : newItemId;

      batch.set(
        db.collection("matched").doc(`${sourceId}__${targetId}`),
        {
          sourceId,
          targetId,
          score: Number(score.toFixed(3)),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    try {
      await batch.commit();
    } catch (err) {
      console.error("onItemCreated: batch commit failed", err);
    }
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
   🧹 CLEANUP CLAIMED ITEMS (48 HOURS AFTER CLAIM)
   Runs every 24 hours.
   TTL = 48 h — once an item is claimed/returned it no
   longer needs to appear in the feed.
   Handles legacy items that have no claimedAt field by
   falling back to createdAt so they are never orphaned.
   ===================================================== */
exports.cleanupClaimedItems = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    // 48 hours — short enough to keep the feed clean,
    // long enough for the owner to see the resolution.
    const CLAIMED_TTL_MS = 48 * 60 * 60 * 1000;
    const cutoffMillis = Date.now() - CLAIMED_TTL_MS;
    const cutoff = admin.firestore.Timestamp.fromMillis(cutoffMillis);

    let snap;
    try {
      // Fetch ALL claimed items in one read.
      // We filter by timestamp in code so we can handle
      // legacy docs that are missing the claimedAt field.
      snap = await db
        .collection("items")
        .where("isClaimed", "==", true)
        .get();
    } catch (err) {
      console.error("cleanupClaimedItems: failed to fetch claimed items", err);
      return;
    }

    const batch = db.batch();
    let deleteCount = 0;

    for (const doc of snap.docs) {
      const data = doc.data();

      // Prefer claimedAt; fall back to createdAt for items
      // claimed before this field was introduced.
      const referenceTs = data.claimedAt ?? data.createdAt;

      if (!referenceTs) continue; // no timestamp at all — skip

      if (referenceTs.toMillis() <= cutoffMillis) {
        batch.delete(doc.ref);
        deleteCount++;
      }
    }

    try {
      await batch.commit();
      console.log(
        `cleanupClaimedItems: deleted ${deleteCount} claimed item(s) older than 48 h`
      );
    } catch (err) {
      console.error("cleanupClaimedItems: batch commit failed", err);
    }
  });

/* =====================================================
   🚨 NOTIFY USER WHEN ACCOUNT IS INVESTIGATED
   Fires whenever a user document is updated.
   Only acts when accountStatus transitions TO 'investigated'.
   ===================================================== */
exports.onUserStatusInvestigated = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only act on the specific transition → 'investigated'
    if (
      before.accountStatus === "investigated" ||
      after.accountStatus !== "investigated"
    ) {
      return;
    }

    const userId = context.params.userId;

    try {
      await db.collection("notifications").add({
        userId,
        type: "account_investigated",
        title: "⚠️ Account Under Investigation",
        message:
          "Your account has been flagged for malpractice. " +
          "You can no longer chat or post items until the investigation is resolved. " +
          "Please contact support if you believe this is a mistake.",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Investigation notification sent to user: ${userId}`);
    } catch (err) {
      console.error(
        `onUserStatusInvestigated: failed to notify user ${userId}`,
        err
      );
    }
  });

/* =====================================================
   🔔 NOTIFY USERS WHEN MATCH IS CREATED
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
