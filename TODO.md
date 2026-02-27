# LostUAE – Similarity Gate for Chat

## Task
Block users from initiating a chat with a lost/found report unless they have
at least 30% similarity (score ≥ 0.30) between one of their own items and the
viewed item (as recorded in the `matched` Firestore collection).

## Steps

- [x] Read and understand all relevant files
  - item_details_screen.dart
  - chat_service.dart / chat_screen.dart / unlock_chat_screen.dart
  - functions/index.js (similarity threshold already 0.30)
  - matched collection schema (sourceId, targetId, score)
- [x] Add `_checkUserSimilarity()` method to `_ItemDetailsScreenState`
- [x] Modify "Chat with owner" `onPressed` to call the similarity gate
- [x] Show blocking dialog when similarity < 30%
- [x] Test: user with no matching items → blocked
- [x] Test: user with ≥ 30% matching item → allowed through

---

## Phase 2 – Unlock validation enhancement (validateAndUnlockChat)

- [x] Add type pairing check (step 9b) to `functions/index.js`
      → Rejects with `invalid_type_pairing` if both items have the same status
- [x] Add similarity check (step 9c) to `functions/index.js`
      → Uses existing `calculateSimilarity` from `similarity.js`
      → Rejects with `similarity_too_low` if score < 0.30
- [x] Add `invalid_type_pairing` + `similarity_too_low` error handlers to
      `lib/screens/chat system/unlock_chat_screen.dart`
- [x] Add `_jaccardSimilarity` helper + same two checks to
      `lib/services/certificate_service.dart` (`_clientSideUnlock` fallback)
