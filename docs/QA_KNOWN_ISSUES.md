# Campus Plug — Known Issues (Phase 1)

**Last updated:** 2026-07-16  
**Purpose:** Issues acceptable for initial launch; track and resolve in Phase 1.

---

## Launch-Blocking Items — Resolved ✅

| ID | Issue | Resolution |
|----|-------|------------|
| BUG-001 | Chat messages silently lost on write failure | `await batch.commit()` in `chat_service.dart` |
| BUG-002 | Explore empty-state category chips broken | Category IDs aligned with `AppConstants` |
| BUG-003 | No retry on vendor load failure | Retry button + error detail added |
| BUG-004 | Duplicate reviews possible | Deterministic `{vendorId}_{buyerId}` upsert |
| BUG-006 | Android Crashlytics native plugin missing | Gradle plugin + release-only collection |

---

## Known Issues — Ship with Tracking

### HIGH (fix in Phase 1 sprint 1)

| ID | Issue | Workaround | Owner |
|----|-------|------------|-------|
| BUG-005 | Home tab search and category filters don't work | Use **Explore** tab for search/filter | Engineering |

### MEDIUM

| ID | Issue | User Impact | Planned Fix |
|----|-------|-------------|-------------|
| BUG-008 | 10s splash delay | Slower cold start; may miss <3s load target | Navigate when auth ready (remove fixed delay) |
| BUG-009 | "Most Orders" sort ineffective | Sort appears random | Populate `completedOrders` on order completion |
| BUG-010 | Home vendors not campus-scoped | May show vendors from other campuses | Filter `getAllVendors()` by `defaultCampusId` |
| BUG-011 | "Buy Now" / "Visit Store" stubs | Users cannot complete purchase in-app | Implement checkout flow or hide buttons |
| BUG-012 | Offline banner inaccurate | May show "Offline" while connected | Use `connectivity_plus` for real network state |

### LOW / Polish

| ID | Issue | Notes |
|----|-------|-------|
| BUG-013 | Deprecated `withOpacity` calls | No functional impact; Flutter 3.44 deprecation |
| BUG-014 | Dead `AuthWrapper` code | No user impact |
| BUG-015 | Duplicate vendor fetches on profile | Minor perf; extra Firestore read |
| BUG-016 | Profile tab placeholder | Show "Coming soon" — set expectations in onboarding |

---

## Features Not Yet Implemented

| Feature | Status | Phase |
|---------|--------|-------|
| Push notifications (FCM) for new messages | TODO in `chat_service.dart` | Phase 1 |
| Firebase Analytics | Not configured | Phase 1 |
| In-app purchasing / order flow | Stub buttons only | Phase 2 |
| User profile editing | Placeholder screen | Phase 1 |
| Firestore composite indexes | May be required for chat queries at scale | Ops — monitor Firebase console |

---

## Performance Caveats

| Area | Caveat |
|------|--------|
| Explore skeleton | Minimum 1.5s skeleton display even on fast networks (intentional anti-flash) |
| Vendor reviews | Profiles show 5 recent reviews; full list via "View All" — pagination not implemented for 100+ reviews |
| Client-side filtering | Search/filter is in-memory after campus fetch — acceptable for <100 vendors |

---

## Error Tracking

| Tool | Status |
|------|--------|
| Firebase Crashlytics (Dart) | ✅ Active — fatal errors + manual `recordError` in chat/shop flows |
| Firebase Crashlytics (Android native) | ✅ Gradle plugin added |
| Firebase Crashlytics (iOS native) | ⚠️ Verify dSYM upload in Xcode archive builds |
| Sentry | Not configured (Crashlytics chosen) |

**Verify after release build:** Force a test crash in release mode and confirm event in [Firebase Console → Crashlytics](https://console.firebase.google.com/).

---

## QA Sign-Off Dependency

Before removing items from this list, each fix must:

1. Have a corresponding entry closed in `QA_BUG_REPORT.md`
2. Pass regression on [`QA_TESTING_CHECKLIST.md`](./QA_TESTING_CHECKLIST.md) affected flows
3. Show no new Crashlytics spikes within 24h of staged rollout
