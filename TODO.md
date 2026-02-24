# LostUAE Firebase Functions – Fix & Enhancement Plan

## Tasks

- [x] Analyze all relevant files (index.js, similarity.js, item_timeout.js, firestore.rules, report_service.dart)
- [x] Step 1: Upgrade `functions/similarity.js` — stopwords + stemming + bigrams + weighted hybrid score
- [x] Step 2: Fix `functions/index.js` — efficient item query, threshold 0.30, add `onUserStatusInvestigated` notification function
- [x] Step 3: Delete `functions/item_timeout.js` — dead broken code, not imported anywhere
- [x] Step 4: Verified all changes are consistent with Firestore rules and Flutter notification reader

## ✅ COMPLETE
