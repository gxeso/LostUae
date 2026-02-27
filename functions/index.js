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
const { v4: uuidv4 } = require("uuid");

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
    unlockCount: 0,
    unlockWindowStart: null,
    unlockAttempts: 0,
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
   🔓 VALIDATE AND UNLOCK CHAT (CALLABLE)
   ===================================================== */

/**
 * Helper: log a failed unlock attempt to unlock_attempts collection.
 */
async function logFailedAttempt(userId, threadId, reason) {
  try {
    await db.collection("unlock_attempts").add({
      userId,
      threadId,
      certificateCode: "",
      attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
      success: false,
      failureReason: reason,
    });
  } catch (err) {
    console.error("logFailedAttempt: failed to write", err);
  }
}

exports.validateAndUnlockChat = functions.https.onCall(async (data, context) => {
  // ── 1. Auth check ──
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to unlock a chat."
    );
  }

  const uid = context.auth.uid;
  const { caseId, lostReportId } = data;

  if (!caseId || !lostReportId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "caseId and lostReportId are required."
    );
  }

  // ── 2. Read user document ──
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    throw new functions.https.HttpsError("not-found", "User not found.");
  }

  const userData = userSnap.data();
  const unlockCount = userData.unlockCount ?? 0;

  // ── 3. Payment check ──
  if (unlockCount > 0) {
    // In production this would verify a real payment token.
    // For now we trust the client-side mock payment and proceed.
    // If the client signals payment_required, throw the error.
    if (data.paymentRequired === true && !data.paymentConfirmed) {
      await logFailedAttempt(uid, caseId, "payment_required");
      throw new functions.https.HttpsError(
        "failed-precondition",
        "payment_required"
      );
    }
  }

  // ── 4. Rate limit check (max 5 attempts per 60 seconds) ──
  const now = admin.firestore.Timestamp.now();
  const windowStart = userData.unlockWindowStart;
  let unlockAttempts = userData.unlockAttempts ?? 0;

  const RATE_WINDOW_MS = 60 * 1000; // 60 seconds
  const MAX_ATTEMPTS = 5;

  if (windowStart && (now.toMillis() - windowStart.toMillis()) < RATE_WINDOW_MS) {
    if (unlockAttempts >= MAX_ATTEMPTS) {
      await logFailedAttempt(uid, caseId, "rate_limit_exceeded");
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "rate_limit_exceeded"
      );
    }
    // Increment attempts within the window
    await userRef.update({ unlockAttempts: admin.firestore.FieldValue.increment(1) });
  } else {
    // Reset window
    await userRef.update({
      unlockWindowStart: now,
      unlockAttempts: 1,
    });
    unlockAttempts = 1;
  }

  // ── 5. Validate participant ──
  const chatRoomSnap = await db.collection("chat_rooms").doc(caseId).get();
  if (!chatRoomSnap.exists) {
    await logFailedAttempt(uid, caseId, "chat_room_not_found");
    throw new functions.https.HttpsError("not-found", "Chat room not found.");
  }

  const chatRoomData = chatRoomSnap.data();
  const participants = chatRoomData.users ?? [];

  if (!participants.includes(uid)) {
    await logFailedAttempt(uid, caseId, "not_a_participant");
    throw new functions.https.HttpsError(
      "permission-denied",
      "You are not a participant in this chat."
    );
  }

  // ── 6. Early return if already unlocked ──
  const caseSnap = await db.collection("cases").doc(caseId).get();
  if (caseSnap.exists && caseSnap.data().isLocked === false) {
    return { success: true, alreadyUnlocked: true };
  }

  // ── 7. Get item category ──
  const itemId = chatRoomData.itemId;
  if (!itemId) {
    await logFailedAttempt(uid, caseId, "item_id_missing");
    throw new functions.https.HttpsError(
      "internal",
      "Item ID not found in chat room."
    );
  }

  const itemSnap = await db.collection("items").doc(itemId).get();
  if (!itemSnap.exists) {
    await logFailedAttempt(uid, caseId, "item_not_found");
    throw new functions.https.HttpsError("not-found", "Item not found.");
  }

  // Use explicit 'category' if present; fall back to 'itemName'
  const itemData = itemSnap.data();
  const itemCategory = (itemData.category && itemData.category.trim())
    ? itemData.category.trim()
    : (itemData.itemName ?? "").trim();

  // ── 8. Verify lost report ownership ──
  // Lost reports are stored in the 'items' collection (status == 'Lost').
  const reportSnap = await db.collection("items").doc(lostReportId).get();
  if (!reportSnap.exists) {
    await logFailedAttempt(uid, caseId, "report_not_found");
    throw new functions.https.HttpsError("not-found", "Lost report not found.");
  }

  const reportData = reportSnap.data();
  if (reportData.userId !== uid) {
    await logFailedAttempt(uid, caseId, "report_not_owned");
    throw new functions.https.HttpsError(
      "permission-denied",
      "This lost report does not belong to you."
    );
  }

  // ── 9. Category match check ──
  // Use explicit 'category' field if present; fall back to 'itemName'
  // (items collection does not have a separate category field by default)
  const reportCategory = (reportData.category && reportData.category.trim())
    ? reportData.category.trim()
    : (reportData.itemName ?? "").trim();

  const normalizedItemCategory = itemCategory.toLowerCase().trim();
  const normalizedReportCategory = reportCategory.toLowerCase().trim();

  // Only enforce category match when both sides have a non-empty value
  if (
    normalizedItemCategory &&
    normalizedReportCategory &&
    normalizedItemCategory !== normalizedReportCategory
  ) {
    await logFailedAttempt(uid, caseId, "category_mismatch");
    throw new functions.https.HttpsError(
      "failed-precondition",
      "category_mismatch"
    );
  }

  // ── 10. Generate certificate code (CERT-XXXX-XXXX) ──
  const rawId = uuidv4().replace(/-/g, "").toUpperCase();
  const certificateCode = `CERT-${rawId.slice(0, 4)}-${rawId.slice(4, 8)}`;

  // ── 11. Create certificate document (30-day expiry) ──
  const issuedAt = now;
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + 30 * 24 * 60 * 60 * 1000
  );

  const certRef = db.collection("certificates").doc();
  await certRef.set({
    certificateCode,
    userId: uid,
    lostReportId,
    category: normalizedReportCategory || normalizedItemCategory,
    issuedAt,
    expiresAt,
    boundThreadId: caseId,
    status: "active",
    pdfPath: null,
  });

  // ── 12. Update case: unlock it ──
  await db.collection("cases").doc(caseId).update({
    isLocked: false,
    unlockedBy: uid,
    unlockedAt: now,
    unlockedWithCertificate: certificateCode,
  });

  // ── 13. Increment unlockCount on user ──
  await userRef.update({
    unlockCount: admin.firestore.FieldValue.increment(1),
  });

  // ── 14. Log successful unlock attempt ──
  await db.collection("unlock_attempts").add({
    userId: uid,
    threadId: caseId,
    certificateCode,
    attemptedAt: now,
    success: true,
    failureReason: null,
  });

  return {
    success: true,
    certificateCode,
    alreadyUnlocked: false,
  };
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
