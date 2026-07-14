# Spike Validation Report — Heal / Safe Place

## Spike Objective

Determine whether an iOS app can shield one specifically selected app using Apple's Screen Time APIs, present a custom shield, open the main app via `ShieldActionResponse.openParentalControlsApp`, route immediately into a Safe Place screen through App Group handoff, and present a minimal placeholder content module with four local outcome actions — without backend, analytics, or notification fallback.

## Test Environment

| Field | Value |
|-------|-------|
| iPhone model | iPhone Air |
| iOS version | 26.5.1 |
| Xcode version | 26.6 |
| Test date | July 13, 2026 |
| Milestone J commit | `acf3b76` |
| Milestone K Phase 2 commit | `d64b221` |
| Blocked app used | Not recorded |
| Screenshots / screen recording | Not recorded |

## Milestone Status (A–K)

| Milestone | Description | Status |
|-----------|-------------|--------|
| A | Repository and empty Xcode shell | Complete |
| B | Entitlements and signing | Complete |
| C | Authorization (main app) | Complete |
| D | One-app selection + persistence | Complete |
| E | Shield application | Complete |
| F | Shield Configuration extension | Complete |
| G | App Group handoff (write path) | Complete |
| H | Shield Action + `openParentalControlsApp` | Complete |
| I | Safe Place handoff routing | Complete |
| J | Safe Place placeholder UI | Complete — real-iPhone pass (`acf3b76`) |
| K | Spike hardening | Complete — Phase 1 validation, Phase 2 fix, retest pass (`d64b221`) |

## Primary Path Result (14-Step)

**Result: Pass** — validated on real iPhone during Milestone J (July 13, 2026).

| Step | Description | Result |
|------|-------------|--------|
| 1 | Authorization granted | Pass |
| 2 | One app selected | Pass |
| 3 | Token persisted | Pass |
| 4 | Shield applied | Pass |
| 5 | Blocked app launch attempted | Pass |
| 6 | Custom shield shown | Pass |
| 7 | "Open Safe Place" tapped | Pass |
| 8 | Handoff marker written | Pass |
| 9 | `openParentalControlsApp` returned | Pass |
| 10 | Main app opens | Pass |
| 11 | Handoff marker read | Pass |
| 12 | Safe Place presented immediately | Pass |
| 13 | Video placeholder + four buttons visible | Pass |
| 14 | Primary path validated | Pass |

## Milestone K Edge-Case Results

Tested on real iPhone after `d64b221` unless noted.

### Reboot persistence

**Result: Pass**

- Shield remained active after reboot; blocked app showed custom shield.
- Open Safe Place completed handoff; Safe Place appeared immediately with placeholder and four buttons.
- After Phase 2 fix: shield status UI matched actual block state on Heal relaunch.

### Force-quit and re-trigger

**Result: Pass**

- After force-quit, shield continued to block the selected app.
- Open Safe Place launched Heal and presented Safe Place immediately.
- Marker was consumed; normal relaunch did not reopen Safe Place.
- After Phase 2 fix: shield status UI matched actual block state on Heal reopen.

### Permission revocation and reauthorization

**Result: Pass** (after `d64b221`)

- Revoking Screen Time authorization routed Heal to `SetupView`.
- No misleading "shield applied" status while authorization was unavailable.
- After reauthorization, UI reflected actual `ManagedSettingsStore` state.
- No automatic shield reapply; user must tap Apply Shield.
- Apply Shield restored block and UI correctly.

**Note:** After revocation, authorization status displayed as "Not determined" rather than "Denied" in at least one observed case. This appears consistent with iOS behavior and was not treated as a spike failure.

### Clear / reapply retest loop

**Result: Pass**

- Clear Shield removed the block; selected app opened normally.
- Reapply Shield restored the block.
- Full Safe Place handoff flow worked again after reapply.

### Safe Place handoff regression (post–Phase 2)

**Result: Pass**

- Shield → Open Safe Place → immediate Safe Place presentation unchanged after K fixes.

### Stale handoff (>5 minutes)

Stale-marker rejection is implemented in `HandoffStore` using the existing five-minute validity window. A dedicated delayed-marker device test was not recorded during Milestone K.

## Pre-Fix Issue and Resolution (Milestone K Phase 2)

### Observed issue (Phase 1)

`SpikeAppState.isShieldApplied` was a session flag set only by Apply/Clear taps. It was not synchronized from `ManagedSettingsStore` on launch, reboot, force-quit, or authorization changes. This caused the UI to disagree with actual block behavior — including a false "shield applied" state after revoke/reauthorize while the app was not blocked.

### Fix (`d64b221`)

- `ShieldService.isPersistedSelectionShielded()` returns true only when the persisted one-app token is present in the store's shield applications.
- `SpikeAppState.syncShieldAppliedStateFromSystem()` refreshes UI state from the store during system refresh, apply, clear, and authorization changes.
- When authorization is not approved, UI shows a safe unavailable state without claiming the OS cleared the shield.
- Stale contradictory footnote messages are cleared on successful store read.

### Retest result

**Pass** — all Phase 2 regression steps confirmed on real iPhone.

## Safe Place Content Prototype — Slice 1 (Single Embed)

**Status:** Complete — real-iPhone pass (July 13, 2026).

| Field | Value |
|-------|-------|
| Scope | Breathing screen → one predefined YouTube Short inside Heal |
| Video ID | `iw4OS1Ki76g` |
| Embed | Official YouTube iframe via `WKWebView` with app Bundle ID identity |
| Later slices | Vertical paging, multi-video, and “I feel better now” overlay not started |

### Device validation

| Check | Result |
|-------|--------|
| Shield handoff → breathing screen | Pass |
| No player before Continue | Pass |
| Continue → Short loads inside Heal | Pass |
| Autoplay after Continue | Pass |
| Playback stays in Heal (no Safari / YouTube app) | Pass |
| Embed error 152-4 resolved via app identity `origin` | Pass |
| Video loops at end | Pass |
| Temporary Exit above player; dismissal returns to normal flow | Pass |
| Shield remains applied after Exit | Pass |
| Normal relaunch does not reopen Safe Place | Pass |

## Outcome Button Evidence

| Button | UI behavior tested | Console `print` logging |
|--------|-------------------|-------------------------|
| The urge passed | Visible; tap had no additional visible UI (expected) | Partially verified earlier; not consistently verifiable during Milestone K |
| Show me another video | Visible; local placeholder feedback confirmed | Partially verified earlier; not consistently verifiable during Milestone K |
| I still need help | Visible; tap had no additional visible UI (expected) | Partially verified earlier; not consistently verifiable during Milestone K |
| Close | Dismissal to normal app flow confirmed | Partially verified earlier; not consistently verifiable during Milestone K |

All four buttons were visible and reachable. Console logs were not consistently verifiable during Milestone K because Xcode debugger/console attachment was not working. Do not treat every outcome `print` as fully verified in the final validation session.

## Known Limitations

- Spike scope is **one app only** — no categories, web domains, or DeviceActivity.
- Safe Place Slice 1 uses a **single in-app YouTube Short embed** — no vertical paging or multi-video feed yet.
- Spike placeholder outcome buttons were replaced in Slice 1; final dismissal overlay belongs to Slice 4.
- Outcome actions use local `print` logging; only "Show me another video" has visible footnote feedback.
- Xcode console attach failed during parts of Milestone K testing.
- Post-revocation authorization may show "Not determined" instead of "Denied".
- `SetupView` does not include explicit "Open Settings" guidance.
- Shield-unavailable message is stored in app state while `SetupView` is shown (not visible until app selection).
- Screenshots and screen recording were not recorded for this report.
- TestFlight, App Store, and Family Controls distribution approval were not validated.

## Features Intentionally Not Tested

- App categories and web domain shielding
- DeviceActivity scheduling
- Notifications or Universal Links as Safe Place entry fallback
- Backend, accounts, analytics, subscriptions
- Social or community features
- Real single-Short YouTube embed playback inside Heal (Slice 1); no recommendation feed or paging yet
- Multiple simultaneously blocked apps
- iPad and Simulator extension runtime behavior
- Dedicated stale-marker device test with a marker older than five minutes
- Complete console verification of every outcome button during Milestone K
- Behavior on iOS versions and devices other than the tested iPhone Air / 26.5.1

## Safari Web Extension block-page spike (14 July 2026)

| Field | Value |
|-------|-------|
| Branch | `spike/safari-web-extension-block-page` |
| Baseline | `main` / `github/master` @ `72a2f3e` |
| Feature | Isolated Safari Web Extension → Heal-controlled block page → Safe Place |
| Xcode / SDK | 26.6 / iOS SDK 26.5 |
| Device | Physical iPhone |
| Classification | **SAFARI-EXT-1 — Full intervention path** |

### Physical-device test cases

| Case | Result |
|------|--------|
| Normal Safari → `https://example.com` | Redirected to Heal-controlled `blocked.html` (not Apple `Website Not Allowed`) |
| Open Safe Place tap | iOS showed `Open this page in “Heal”?`; after approval, Heal opened into Safe Place with no extra setup screen |
| Unrelated websites | Unaffected |
| Extension disabled | Normal access to `example.com` restored |
| Safari Private Browsing (separately enabled) | Same redirect → confirmation → Heal → Safe Place path |

The iOS confirmation prompt occurs **before** switching from Safari to Heal. Opening is not silent or automatic.

Managed Settings website filters (`.auto` / `.specific` / website shields) were **not** part of this path.

### Still unproven for this extension path

- Production-scale adult-domain coverage / remote rule updates
- App Store review and onboarding conversion
- Coexistence / ordering with Managed Settings website filters
- Chrome / non-Safari browsers
- Universal Links vs custom-scheme production security choice

---

## Final Feasibility Conclusion

**GO with constraints**

### Proven on tested device

- One-app selection and persistence
- `ManagedSettings` app shield for the selected token
- Custom shield UI (Shield Configuration extension)
- "Open Safe Place" shield action
- `openParentalControlsApp` opening Heal
- App Group handoff write, read, and consumption
- Immediate Safe Place presentation after shield-originated launch
- Static placeholder video module (superseded for Slice 1 by in-app YouTube embed)
- Four outcome buttons and their approved local UI behavior
- Reboot and force-quit behavior on the tested device
- Revoke/reauthorization handling after the Milestone K fix
- Truthful shield status synchronization from `ManagedSettingsStore`
- Clear/reapply retest loop
- Safari Web Extension isolated intervention path (**SAFARI-EXT-1**, 14 July 2026)

### Not proven

- App Store / Family Controls distribution approval
- Behavior across other iOS versions and devices
- Category or domain shielding
- DeviceActivity scheduling
- Fallback behavior if `openParentalControlsApp` is unavailable or fails
- Production video/feed architecture (Slice 1 proves one embed only)
- Long-term production persistence guarantees
- Dedicated stale-marker device test older than five minutes
- Complete console verification of every outcome button during Milestone K
- Production-scale Safari extension domain coverage and Managed Settings coexistence

## Evidence and Remaining Uncertainty

**Evidence:** Real-iPhone passes for Milestone J primary path and Milestone K edge cases documented above on iPhone Air, iOS 26.5.1, Xcode 26.6, July 13, 2026.

**Remaining uncertainty:**

- Whether `openParentalControlsApp` and handoff behavior remain reliable on untested OS builds and hardware
- Apple approval requirements and timeline for Family Controls distribution
- Whether ManagedSettings shield persistence policies change across OS updates
- Appropriate product fallback if `openParentalControlsApp` fails on supported devices in the field
- Whether stale-marker rejection behaves as implemented when a marker is actually older than five minutes on device
