# Campus Plug — QA Bug Report

**Report date:** 2026-07-16  
**Scope:** Pre-launch comprehensive QA (code review + static analysis + automated tests)  
**Environment:** Linux CI host; device/simulator manual tests pending execution by QA team

---

## Summary

| Severity | Found | Fixed in this pass | Open |
|----------|-------|-------------------|------|
| CRITICAL | 2 | 2 | 0 |
| HIGH | 4 | 3 | 1 |
| MEDIUM | 6 | 0 | 6 |
| LOW | 4 | 0 | 4 |

---

## CRITICAL — Fixed

### BUG-001: Chat messages silently fail to persist
- **Severity:** CRITICAL
- **Area:** Chat
- **File:** `mobile_app/lib/services/chat_service.dart`
- **Description:** `batch.commit().catchError((_) {})` swallowed Firestore write failures. UI showed success while messages could be lost; Crashlytics never recorded write errors.
- **Repro:** Send message when Firestore rules deny write or batch fails.
- **Fix:** `await batch.commit()` — errors propagate to `chat_screen.dart` try/catch and Crashlytics. Offline persistence still queues writes locally.
- **Status:** ✅ Fixed

### BUG-002: Explore empty-state category chips broken
- **Severity:** CRITICAL (search/filter blocker)
- **Area:** Vendor discovery
- **File:** `mobile_app/lib/screens/explore_screen.dart`
- **Description:** Empty-state ActionChips set `_selectedCategory = 'Food'` (display name) but filter compares against category IDs (`'food'`). Tapping suggested categories returned zero results.
- **Repro:** Search for nonexistent vendor → tap "Food" chip in empty state.
- **Fix:** Chips now use `AppConstants.categories` IDs (`food`, `services`, `tutoring`).
- **Status:** ✅ Fixed

---

## HIGH

### BUG-003: Vendor fetch failure with no recovery
- **Severity:** HIGH
- **Area:** Explore
- **File:** `mobile_app/lib/screens/explore_screen.dart`
- **Description:** Network error left `_cachedVendors == null` with static error text and no retry.
- **Fix:** Added `_fetchError` state, error detail, and **Retry** button.
- **Status:** ✅ Fixed

### BUG-004: Duplicate reviews possible
- **Severity:** HIGH
- **Area:** Reviews
- **Files:** `firestore_service.dart`, `review_form_dialog.dart`
- **Description:** `createReview` used random timestamp-based IDs; bypassing UI guard could create multiple reviews per buyer.
- **Fix:** Deterministic doc ID `{vendorId}_{buyerId}` with `SetOptions(merge: true)` upsert.
- **Status:** ✅ Fixed

### BUG-005: Home screen search and category filters non-functional
- **Severity:** HIGH
- **Area:** Home feed
- **File:** `mobile_app/lib/screens/home_screen.dart`
- **Description:** Search `TextField` has no `onChanged`; category chips update state but do not filter product streams.
- **Repro:** Type in home search bar or tap category on Home tab — no filtering occurs.
- **Status:** ⚠️ Open — requires implementation

### BUG-006: Crashlytics Android native plugin missing
- **Severity:** HIGH (observability)
- **Files:** `android/app/build.gradle.kts`, `android/settings.gradle.kts`
- **Description:** Dart Crashlytics handlers were configured but Android Gradle lacked `com.google.firebase.crashlytics` plugin — native crashes may not symbolicate/upload.
- **Fix:** Added Crashlytics Gradle plugin; enabled collection in release only via `main.dart`.
- **Status:** ✅ Fixed

---

## MEDIUM — Open

### BUG-007: Explore refresh triggered from `build()`
- **Area:** Explore
- **Description:** `_checkAndRefreshCache()` called on every rebuild → redundant Firestore fetches.
- **Fix:** Replaced with `Timer.periodic` (5 min) + lifecycle resume check.
- **Status:** ✅ Fixed (was MEDIUM, addressed proactively)

### BUG-008: Splash screen 10-second fixed delay
- **Area:** Startup / Performance
- **File:** `splash_screen.dart`
- **Impact:** App load may exceed 3s target regardless of auth readiness.
- **Status:** ⚠️ Open

### BUG-009: `completedOrders` never populated
- **Area:** Explore sort
- **Impact:** "Most Orders" sort always returns arbitrary order (all zeros).
- **Status:** ⚠️ Open

### BUG-010: Home "Top Student Vendors" ignores campus filter
- **Area:** Home
- **Impact:** Shows vendors from all campuses, not default campus.
- **Status:** ⚠️ Open

### BUG-011: Product detail stub buttons
- **Area:** Commerce
- **File:** `product_detail_screen.dart`
- **Impact:** "Visit Store" and "Buy Now" do nothing.
- **Status:** ⚠️ Open (expected pre-launch gap if ordering not in scope)

### BUG-012: Offline banner uses pending-write heuristic
- **Area:** Chat UX
- **File:** `chat_screen.dart`
- **Impact:** "Offline" banner shows whenever any message is pending, not true connectivity state.
- **Status:** ⚠️ Open

---

## LOW — Open

### BUG-013: Deprecated `withOpacity` in several widgets
- **Files:** `product_card.dart`, `onboarding_screen.dart`, `role_selection_screen.dart`
- **Status:** ⚠️ Open

### BUG-014: Unused `AuthWrapper` dead code in `main.dart`
- **Status:** ⚠️ Open

### BUG-015: Duplicate `getVendor` FutureBuilders on vendor profile
- **File:** `vendor_profile_screen.dart`
- **Status:** ⚠️ Open (extra Firestore read)

### BUG-016: Profile tab placeholder ("coming soon")
- **File:** `home_screen.dart`
- **Status:** ⚠️ Open

---

## Manual Test Results (Pending Device Execution)

The following require physical devices or emulators with Firebase credentials. Mark Pass/Fail when executed using [`QA_TESTING_CHECKLIST.md`](./QA_TESTING_CHECKLIST.md).

| Flow | Android Emulator | Android Physical | iOS Simulator | iOS Physical |
|------|------------------|------------------|---------------|--------------|
| Vendor discovery | ☐ Pending | ☐ Pending | ☐ Pending | ☐ Pending |
| Chat real-time (<2s) | ☐ Pending | ☐ Pending | ☐ Pending | ☐ Pending |
| Review submit + rating update | ☐ Pending | ☐ Pending | ☐ Pending | ☐ Pending |
| Network loss recovery | ☐ Pending | ☐ Pending | ☐ Pending | ☐ Pending |
| 100-message stress test | ☐ Pending | ☐ Pending | ☐ Pending | ☐ Pending |

---

## Static Analysis (2026-07-16)

```
flutter analyze → 18 info-level issues, 0 errors
```

No analyzer errors blocking release. Info items are deprecation warnings and style hints.
