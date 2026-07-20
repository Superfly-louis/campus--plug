# Campus Plug — QA Testing Checklist

**App:** Campus Plug Mobile (`mobile_app/`)  
**Version:** Pre-launch QA  
**Last updated:** 2026-07-16  
**Error tracking:** Firebase Crashlytics (Dart + Android native)

---

## Pre-Test Setup

| # | Step | Done |
|---|------|------|
| 1 | Install latest build on test device/emulator | ☐ |
| 2 | Confirm Firebase project `campus--plug` is reachable | ☐ |
| 3 | Verify 30+ vendor profiles exist in production Firestore (`vendors` collection, `campusId: cu_miotso`) | ☐ |
| 4 | Prepare **two accounts**: one buyer, one vendor (linked to a vendor profile) | ☐ |
| 5 | Enable Crashlytics dashboard access for test session | ☐ |
| 6 | Note device model, OS version, network type (WiFi / 4G) | ☐ |

### Test Devices

| Platform | Target | Min OS | Device / Emulator | Tester | Date |
|----------|--------|--------|-------------------|--------|------|
| Android | Emulator | API 26+ | | | |
| Android | Physical | — | Redmi Note 9 (or similar) | | |
| iOS | Simulator | iOS 13+ | | | |
| iOS | Physical | — | iPhone 12 (or similar) | | |

---

## 1. Manual Testing — Full User Journeys

### Flow 1: Vendor Profile Discovery

| # | Step | Expected Result | Pass | Notes |
|---|------|-----------------|------|-------|
| 1.1 | Open app, complete login as buyer | Home screen loads | ☐ | |
| 1.2 | Navigate to **Explore** tab | Vendor grid loads for campus | ☐ | |
| 1.3 | Search for vendor by name | Results filter within ~500ms | ☐ | |
| 1.4 | Tap category chip (e.g. Food) | Only matching vendors shown | ☐ | |
| 1.5 | Change sort (Top Rated / Newest / Most Orders) | List re-sorts correctly | ☐ | |
| 1.6 | Tap vendor card | Profile screen opens | ☐ | |
| 1.7 | Verify profile data | Name, description, rating, reviews, logo load | ☐ | Target: <2s load |

### Flow 2: Chat & Ordering

| # | Step | Expected Result | Pass | Notes |
|---|------|-----------------|------|-------|
| 2.1 | From vendor profile, tap **Message Vendor** | Chat opens or bootstrap screen shows | ☐ | |
| 2.2 | Send message as buyer | Message appears in chat bubble | ☐ | |
| 2.3 | On vendor device/account, open Messages | New chat appears in inbox | ☐ | |
| 2.4 | Verify delivery time | Message arrives within **2 seconds** | ☐ | Record actual: ___s |
| 2.5 | Vendor sends reply | Buyer sees reply in real time | ☐ | |
| 2.6 | Navigate away and return to chat | Full history persists | ☐ | |
| 2.7 | Kill app and reopen chat | History intact (no data loss) | ☐ | |

### Flow 3: Leaving a Review

| # | Step | Expected Result | Pass | Notes |
|---|------|-----------------|------|-------|
| 3.1 | Return to vendor profile after chat | Profile loads with current rating | ☐ | |
| 3.2 | Tap **Leave Review** | Review dialog opens | ☐ | |
| 3.3 | Submit 5-star review with text | Success snackbar shown | ☐ | |
| 3.4 | Verify review on profile | Review appears within **1 minute** | ☐ | |
| 3.5 | Verify `ratingAverage` / `ratingCount` | Averages update correctly | ☐ | |
| 3.6 | Attempt second review | Prompted to edit existing review | ☐ | |

---

## 2. Network Conditions

| # | Scenario | Steps | Expected | Pass | Notes |
|---|----------|-------|----------|------|-------|
| N.1 | WiFi (baseline) | Run Flows 1–3 | All pass | ☐ | |
| N.2 | 4G | Disable WiFi, use cellular | App usable, chat <2s | ☐ | |
| N.3 | 3G throttle | DevTools / Charles 3G profile | Graceful loading, no crash | ☐ | |
| N.4 | Network loss mid-chat | Disable WiFi while sending message | Pending indicator or retry; no crash | ☐ | |
| N.5 | Network restore | Re-enable WiFi after N.4 | Pending messages sync | ☐ | |

---

## 3. Performance Benchmarks

| Metric | Target | Actual | Pass |
|--------|--------|--------|------|
| Cold app load (4G) | <3s to interactive | | ☐ |
| Vendor profile load | <2s | | ☐ |
| Chat message delivery | <2s | | ☐ |
| Search/filter response | <500ms | | ☐ |
| Profile photo load | <2s | | ☐ |

**How to measure:** Use stopwatch for UX timings; Flutter DevTools Performance tab for frame drops.

---

## 4. Stress Testing

| # | Test | Expected | Pass | Notes |
|---|------|----------|------|-------|
| S.1 | Send 100 messages rapidly | All arrive, no duplicates, no crash | ☐ | |
| S.2 | Switch between 5+ chats quickly | No lag, correct messages per chat | ☐ | |
| S.3 | Open chat → kill app → reopen | History intact | ☐ | |
| S.4 | Background/foreground 10× rapidly | No crash, chat state preserved | ☐ | |
| S.5 | Vendor with 100+ reviews | Pagination / list scrolls smoothly | ☐ | |

---

## 5. Bug Severity Reference

| Severity | Examples | Launch blocker? |
|----------|----------|-----------------|
| **CRITICAL** | Crashes, data loss, can't send message/review, chat delay >5s | Yes — fix immediately |
| **HIGH** | Search/filter broken, profiles don't load, intermittent message loss | Yes — fix before launch |
| **MEDIUM** | Minor UX, acceptable perf, rare edge cases | Track for Phase 1 |
| **LOW** | Polish, animations, nice-to-haves | Phase 1+ |

Log all findings in [`QA_BUG_REPORT.md`](./QA_BUG_REPORT.md).

---

## 6. Pre-Launch Gate Checklist

| Requirement | Status |
|-------------|--------|
| Zero critical crashes in 48-hour soak test | ☐ |
| All HIGH-severity bugs fixed | ☐ |
| All five core features work end-to-end | ☐ |
| Chat real-time delivery <2s verified on 4G | ☐ |
| No data loss (messages, reviews persist) | ☐ |
| App loads in <3s on 4G | ☐ |
| Handles network loss gracefully | ☐ |
| 30+ vendor profiles with complete data in production | ☐ |
| Tested on iOS and Android (emulator + physical) | ☐ |
| No layout shifts or visual glitches on target devices | ☐ |
| Crashlytics receiving events in Firebase console | ☐ |

---

## 7. Automated Tests (CI / Local)

Run before each release candidate:

```bash
cd mobile_app
flutter analyze
flutter test
```

| Suite | Covers |
|-------|--------|
| `test/services/chat_service_test.dart` | Chat ID stability |
| `test/services/firestore_service_test.dart` | Review upsert key |
| `test/widget_test.dart` | App constants smoke test |

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| QA Lead | | | |
| Engineering | | | |
| Product | | | |
