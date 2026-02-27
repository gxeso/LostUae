# Certificate-Based Chat Unlock System — Implementation TODO

## New Files Created ✅
- [x] lib/models/certificate_model.dart
- [x] lib/models/unlock_attempt_model.dart
- [x] lib/models/lost_report_model.dart — fromMap() uses itemName as category fallback
- [x] lib/services/mock_payment_service.dart
- [x] lib/services/certificate_service.dart — queries items collection (status=Lost) for lost reports
- [x] lib/screens/chat system/unlock_chat_screen.dart

## Existing Files Modified ✅
- [x] lib/screens/chat system/case_model.dart — added isLocked, unlockedBy, unlockedAt, unlockedWithCertificate + isParticipant() + isChatAccessible
- [x] lib/screens/chat system/chat_service.dart — added isLocked: true on case creation
- [x] lib/screens/chat system/chat_screen.dart — added locked/unlocked UI + StreamBuilder on cases/{caseId}
- [x] functions/index.js — added unlockCount fields + validateAndUnlockChat callable + logFailedAttempt helper
                         — queries items/{lostReportId} (not lost_reports) + itemName as category fallback
- [x] functions/package.json — added uuid: ^9.0.0
- [x] firestore.rules — modified messages create rule (isLocked check) + added certificates + unlock_attempts rules
- [x] pubspec.yaml — added cloud_functions: ^6.0.6

## Bug Fix Applied ✅
- [x] getUserLostReports() now queries items collection (status=Lost) — fixes empty list issue
- [x] getLostReport() now reads from items collection
- [x] getItemCategoryForCase() uses itemName as fallback when category field is absent
- [x] validateAndUnlockChat Cloud Function queries items/{lostReportId} instead of lost_reports/{lostReportId}
- [x] Category matching uses itemName as fallback on both sides; skipped if either side is empty

## Follow-up Steps
- [x] flutter pub get — completed
- [x] cd functions && npm install — completed
- [ ] firebase deploy --only functions
- [ ] firebase deploy --only firestore:rules
