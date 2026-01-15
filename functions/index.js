/**
 * Firebase Cloud Function (v2)
 * Trigger: when a new item is created
 * Purpose: compute similarity with existing items and store rich match data
 */

const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { calculateSimilarity } = require("./similarity.js");

admin.initializeApp();
const db = admin.firestore();

exports.onItemCreated = onDocumentCreated(
  "items/{itemId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const newItem = snap.data();
    const newItemId = event.params.itemId;

    // Safety check
    if (!newItem.description || typeof newItem.description !== "string") {
      return;
    }

    // Fetch all existing items
    const snapshot = await db.collection("items").get();
    const batch = db.batch();

    // Tune this later if needed
    const SIMILARITY_THRESHOLD = 0.3;

    snapshot.forEach((doc) => {
      // Skip comparing item with itself
      if (doc.id === newItemId) return;

      const other = doc.data();
      if (!other.description || typeof other.description !== "string") {
        return;
      }

      // OPTIONAL: Lost ↔ Found only (recommended)
      if (
        newItem.status &&
        other.status &&
        newItem.status.toLowerCase() === other.status.toLowerCase()
      ) {
        return;
      }

      // Calculate similarity score
      const score = calculateSimilarity(
        newItem.description,
        other.description
      );

      if (score < SIMILARITY_THRESHOLD) return;

      // Normalize IDs to avoid duplicates
      const sourceId = newItemId < doc.id ? newItemId : doc.id;
      const targetId = newItemId < doc.id ? doc.id : newItemId;

      const matchId = `${sourceId}__${targetId}`;
      const ref = db.collection("matched").doc(matchId);

      // Write full match document
      batch.set(
        ref,
        {
          matchId,

          sourceId,
          targetId,

          descriptionA: newItem.description,
          descriptionB: other.description,

          reportIdA: newItem.reportId ?? null,
          reportIdB: other.reportId ?? null,

          score,

          // Can be filled later if you add location logic
          distanceKm: null,

          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    // Commit all matches at once
    await batch.commit();
  }
);
