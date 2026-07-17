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
| Feature | Isolated Safari Web Extension → Heal-controlled block page → Safe Place (`example.com` domain family) |
| Xcode / SDK | 26.6 / iOS SDK 26.5 |
| Device | Physical iPhone |
| Classification | **SAFARI-EXT-1 — Full intervention path** |

### Physical-device test cases

| Case | Result |
|------|--------|
| Normal Safari → `https://example.com` | Redirected to Heal-controlled `blocked.html` (not Apple `Website Not Allowed`) |
| Normal Safari → `https://www.example.com` | Also redirected (tested subdomain; not every subdomain exhaustively tested) |
| Open Safe Place tap | iOS showed `Open this page in “Heal”?`; after approval, Heal opened into Safe Place with no extra setup screen |
| Unrelated websites | Unaffected |
| Extension disabled | Normal access to `example.com` restored |
| Safari Private Browsing (separately enabled) | Same redirect → confirmation → Heal → Safe Place path |

Validated scope: `example.com` domain family; apex and tested `www` subdomain redirect; unrelated websites unaffected. Exact-host-only exclusion was not demonstrated and is not a spike requirement.

The iOS confirmation prompt occurs **before** switching from Safari to Heal. Opening is not silent or automatic.

Managed Settings website filters (`.auto` / `.specific` / website shields) were **not** part of this path.

### Still unproven for this extension path

- Production domain-list productization (see later **SAFARI-DNR-CAPACITY-FULL-1** / **SAFARI-PERMISSION-ALL-1** for capacity feasibility; importer/licensing/onboarding still open)
- Remote rule updates
- App Store review and onboarding conversion
- Universal Links vs custom-scheme production security choice

---

## Safari + ManagedSettings `.specific` coexistence spike (15 July 2026)

| Field | Value |
|-------|-------|
| Branch | `spike/safari-managedsettings-coexistence` |
| Baseline | `main` @ `53b9ef0` |
| Feature | Safari Web Extension + named-store `blockedByFilter = .specific([WebDomain(domain: "example.com")])` |
| Xcode / SDK | 26.6 / iOS SDK 26.5 |
| Device | Physical iPhone |
| Classification | **COEXIST-SPECIFIC-1 — Safari custom intervention + Apple generic fallback** |

### Physical-device test cases

| Case | Result |
|------|--------|
| Normal Safari → `https://example.com` (both mechanisms active) | Heal-controlled extension page (Safari extension won execution); not Apple `Website Not Allowed` |
| Normal Safari → Open Safe Place | iOS confirmation → Heal opened into Safe Place |
| Safari Private Browsing → `https://example.com` | Heal-controlled extension page; Open Safe Place → Heal → Safe Place |
| Chrome → `https://example.com` | Apple generic `Website Not Allowed`; no Heal button |
| Unrelated websites | Unaffected in Safari and Chrome |
| Clear dedicated `.specific` store | Chrome access to `example.com` restored |
| Disable Safari extension (after clear or separately) | Safari access to `example.com` restored |

Validated scope: `example.com` only; both Safari extension rules and Managed Settings `.specific` filter active on dedicated store `coexistenceSpecific`. Automatic adult-category blocking is **not** claimed solved.

**Proven:** Hybrid architecture works on tested device — Safari gets Heal intervention UI via extension; Chrome gets Apple generic blocking via `.specific`.

**Still unproven at time of SPECIFIC spike:** see **COEXIST-AUTO-1** below for Stage 2A `.auto` (explicit domain); classifier-selected domain coexistence remains Stage 2B.

---

## Safari + ManagedSettings `.auto` coexistence spike Stage 2A (15 July 2026)

| Field | Value |
|-------|-------|
| Branch | `spike/safari-managedsettings-coexistence` |
| Baseline | `main` @ `53b9ef0` |
| Feature | Safari Web Extension + named-store `blockedByFilter = .auto([WebDomain(domain: "example.com")], except: [])` |
| Named store | `coexistenceAuto` (mutual exclusion with `coexistenceSpecific`) |
| Xcode / SDK | 26.6 / iOS SDK 26.5 |
| Device | Physical iPhone |
| Classification | **COEXIST-AUTO-1 — Safari custom intervention + Apple generic fallback** |

### Physical-device test cases

| Case | Result |
|------|--------|
| Normal Safari → `https://example.com` (extension + `.auto` active) | Heal-controlled extension page (Safari extension won execution) |
| Normal Safari → Open Safe Place | iOS confirmation → Heal opened into Safe Place |
| Safari Private Browsing → `https://example.com` | Heal-controlled extension page; Open Safe Place → Heal → Safe Place |
| Chrome → `https://example.com` | Apple generic `Website Not Allowed`; no Heal button |
| Unrelated websites | Unaffected in Safari and Chrome |
| Clear dedicated Auto store | Chrome access to `example.com` restored |
| Disable Safari extension after clear | Safari access to `example.com` restored |

### Scope distinction

Stage 2A used `.auto([WebDomain(domain: "example.com")], except: [])` — an **explicitly supplied harmless domain**. This proves the `.auto` policy path alongside the Safari extension. It does **not** prove that Apple’s adult-content classifier independently selected `example.com`.

**Separately recorded:** Apple classifier-selected domain coexistence: **unproven** (Stage 2B pending).

**Proven:** Same hybrid pattern as COEXIST-SPECIFIC-1 for the `.auto` policy with an explicit test domain.

**Still unproven:** Classifier-selected domain coexistence; automatic adult-category blocking at production scale; Stage 2B.

---

## Safari + ManagedSettings `.auto()` classifier-only coexistence spike Stage 2B (15 July 2026)

| Field | Value |
|-------|-------|
| Branch | `spike/safari-managedsettings-coexistence` |
| Baseline | `main` @ `53b9ef0` |
| Feature | Safari Web Extension + named-store `blockedByFilter = .auto()` (classifier-only) |
| Named store | `coexistenceAuto` |
| Xcode / SDK | 26.6 / iOS SDK 26.5 |
| Device | Physical iPhone |
| Classification | **COEXIST-AUTO-CLASSIFIER-1 — Safari custom intervention + Apple generic fallback** |

### Prerequisite: extension-only diagnostic

Before coexistence testing, with Managed Settings Auto cleared:

| Case | Result |
|------|--------|
| Normal Safari → classifier-selected test domain | Heal-controlled extension page |
| Private Safari → same domain | Heal-controlled extension page |
| Chrome → same domain | Normal site (Auto cleared) |
| Diagnostic marker on `example.com` | Confirmed newest extension bundle installed |

Temporary Safari domain rule and diagnostic marker were used for device testing only and **removed before commit**.

### Coexistence test cases (classifier-only `.auto()` active)

| Case | Result |
|------|--------|
| Normal Safari → classifier-selected test domain | Heal-controlled extension page; Open Safe Place → Heal → Safe Place |
| Safari Private Browsing → same domain | Heal-controlled extension page; same Safe Place path |
| Chrome → same domain | Apple generic `Website Not Allowed`; no Heal button |
| Unrelated websites | Unaffected in Safari and Chrome |

Apple’s adult-content classifier independently blocked the test domain under `.auto()`. The Safari Web Extension also covered that domain during the device test (temporary local rule; not committed).

### Architecture conclusion

- **Safari** can provide Heal’s custom block page and Safe Place button when Heal’s Safari Web Extension rules cover the domain.
- **Managed Settings `.auto()`** can provide Apple’s generic restriction page in Chrome and other affected browsers.
- For Safari to show Heal’s page, **Heal’s Safari domain rules must also cover the domain** — Apple’s classifier data is not exposed to the Safari extension.
- Heal still needs its **own Safari domain coverage** separate from Apple’s classifier.

Production-scale domain-list architecture is **not** claimed solved.

---

## Safari DNR capacity + broad permission spike (16 July 2026)

| Field | Value |
|-------|-------|
| Branch | `spike/safari-domain-rules-capacity-1000` |
| Baseline | `main` / `github/master` @ `06c3fcb` |
| Feature | Temporary full static DNR capacity set + temporary `<all_urls>` website-access permission |
| Xcode / SDK | 26.6 / iOS SDK 26.5 |
| Device | Physical iPhone |
| Classifications | **SAFARI-PERMISSION-ALL-1**; **SAFARI-DNR-CAPACITY-FULL-1** |

### Classifications

**SAFARI-PERMISSION-ALL-1** — one broad Safari website-access permission (`<all_urls>`) replaced impractical per-domain approvals; DNR redirects for covered test domains succeeded; unrelated sites remained accessible; normal and Private Browsing both worked.

**SAFARI-DNR-CAPACITY-FULL-1** — **76,743** domain-specific static DNR rules (including the `example.com` fixture) built, signed, installed, and loaded on a physical iPhone with no noticeable delay, crash, freeze, or rule-loading failure during the test.

### Physical-device evidence (aggregates only)

| Case | Result |
|------|--------|
| Static DNR rule count | 76,743 domain-specific rules, including `example.com` |
| Ruleset sampling | Responsive imported domains near the start, middle, and end of the generated ruleset redirected correctly |
| `example.com` (normal + Private Safari) | Heal-controlled page; Open Safe Place worked |
| Chrome with System Website Filtering disabled | Unaffected for imported test domains |
| Unrelated Safari / Chrome sites | Remained accessible |
| Permission model | One `<all_urls>` host permission / WAR match granted broad access; DNR rules still controlled actual blocking scope |
| Runtime | No noticeable delay, crash, freeze, or rule-loading failure observed |

No tested adult hostname is recorded in this report. Third-party domains and temporary generated capacity rules were **removed before commit**; product files were restored to the `example.com` fixture only.

### Production adoption still required

Capacity and broad-permission feasibility are proven for this spike only. Production adoption still requires:

- a permanent hosts-file importer;
- licensing and attribution notices;
- a product generator design for `<all_urls>`;
- snapshot / version / hash tracking;
- onboarding and App Store explanation for broad website access;
- a policy for local verified additions and false positives;
- periodic list cleanup and revalidation for production maintenance.

Production list maintenance should assume:

- inactive or non-resolving domains may be removed after a defined grace period;
- temporary downtime alone must not immediately remove a domain;
- domains can change ownership or content category, creating false positives;
- parked domains, redirects, duplicates, malformed entries, and stale subdomains should be reviewed;
- production use should include snapshot/version tracking, periodic validation, and allowlist handling.

This cleanup was **not** performed during the capacity spike because the spike tested Safari rule capacity, not list quality.

---

## Production Safari Domain List v1 (16 July 2026)

| Field | Value |
|-------|-------|
| Branch | `feat/production-safari-domain-list-v1` |
| Feature | Verified-license production Safari domain list + product `<all_urls>` permission model |
| Classification | **SAFARI-DOMAIN-LIST-PROD-1** |
| Device | Physical iPhone |
| Production count | **63,311** domain-specific DNR rules |

### Included verified-license sources

- BigDargon adult list — MIT
- Sinfonietta pornography — MIT
- Sinfonietta snuff — MIT
- Tiuxo pornography — CC BY 4.0

Clefspeare13/pornhosts, brijrajparmar27/host-sources, and the merged StevenBlack porn-only alternate contribute **no** production domains. Raw upstream snapshots remain outside the repository.

### Physical-device evidence (aggregates only)

| Case | Result |
|------|--------|
| Static DNR rule count | 63,311 domain-specific rules loaded successfully |
| Ruleset sampling | Responsive domains near the start, middle, and end redirected to Heal |
| Normal Safari | Heal intervention page; Open Safe Place worked |
| Private Browsing | Heal intervention page; Open Safe Place worked |
| Unrelated Safari websites | Remained accessible |
| Chrome with System Website Filtering disabled | Unaffected |
| Chrome with System Website Filtering enabled | Apple generic fallback behavior retained |
| Permission model | One `<all_urls>` host permission / WAR match; DNR rules control blocking scope |
| Runtime | No noticeable delay, crash, freeze, or rule-loading failure |

Tested hostnames are not recorded. Updates currently require a new app build (no remote list updates).

### Future maintenance still required

- inactive / stale domains, ownership drift, redirects, false positives
- allowlist review and carefully reviewed local additions
- snapshot / hash tracking for each verified upstream source
- periodic revalidation; grace-period removal; no immediate removal for temporary downtime

---

## Safari Extension onboarding foundation (16 July 2026)

| Field | Value |
|-------|-------|
| Branch | `feat/safari-extension-onboarding-foundation` |
| Feature | Product Safari Extension enablement loop via public iOS 26.2+ SafariServices APIs |
| Classification | **SAFARI-ONBOARDING-FOUNDATION-1** |
| Device | Physical iPhone |
| APIs | `SFSafariExtensionManager.stateOfExtension(withIdentifier:)`; `SFSafariExtensionState.isEnabled`; `SFSafariSettings.openExtensionsSettings(forIdentifiers:)` |
| Extension ID | `com.itamar.Heal.HealSafariExtension` |

### Physical-device evidence

| Case | Result |
|------|--------|
| Extension off | Heal reported **disabled** |
| Open Safari Extension Settings | Opened Heal’s extension detail directly |
| Enable / disable, then return to Heal | Status refreshed automatically on foreground (`scenePhase` active) |
| Remove All Websites permission while extension remains on | Heal still reported **enabled** |
| Disable Private Browsing while normal enablement remains on | Heal still reported **enabled** |
| System Website Filtering enable / disable | Continued to work |

No unexpected behavior observed during these checks.

### Product conclusions

1. `isEnabled` proves **only** that the Safari Web Extension is enabled.
2. It does **not** prove Always Allow on Every Website (All Websites) permission or Private Browsing enablement.
3. **Required setup order:** complete Safari extension setup (enable, Always Allow on Every Website, Private Browsing) **before** enabling System Website Filtering.
4. Automatic foreground refresh on appear and when returning to the app is sufficient; a manual Refresh control is not required.

### Device observation — greyed Safari extension settings

On the tested device, Safari extension settings were **greyed out** while System Website Filtering was active. This is a **physical-device observation**, not a claimed public API guarantee. Product onboarding should still instruct users to finish Safari extension setup before enabling System Website Filtering.

---

## Safari protection test artifact (17 July 2026)

| Field | Value |
|-------|-------|
| Branch | `spike/safari-protection-test-artifact` |
| Feature | Isolated path-specific Safari DNR test URL → dedicated test block page → user-tapped `heal://safe-place?source=safariProtectionTest` |
| Classification | **SAFARI-PROTECTION-TEST-ARTIFACT-1** |
| Device | Physical iPhone |
| Test URL | `https://example.com/heal-safari-protection-test` |
| DNR `urlFilter` | `\|https://example.com/heal-safari-protection-test\|` (exact anchored URL; not whole-domain) |
| Ruleset | `heal_safari_protection_test` → `safari-protection-test-rules.json` (one `main_frame` redirect) |
| Test page | `blocked-test.html` |
| Deep link | `heal://safe-place?source=safariProtectionTest` (user tap only) |

### Physical-device evidence

| Case | Result |
|------|--------|
| Exact test URL | Redirected to dedicated **Safari Protection Test** page (`blocked-test.html`) |
| `https://example.com/` | Loaded normally (unaffected) |
| Unrelated website | Loaded normally (unaffected) |
| Verified production-listed domain | Redirected to existing production `blocked.html` (unaffected) |
| Test page → Open Safe Place | iOS confirmation shown; Heal opened; Safe Place displayed |
| Unexpected behavior | None observed |

Production adult-domain hostnames used for the production-block check are not recorded here.

### Scope boundary for this milestone

This artifact proves the extension can redirect a harmless path-specific test URL to a dedicated test page and that the user-gesture deep link still opens Heal / Safe Place.

It does **not** yet:

- parse the `source=safariProtectionTest` query in the app;
- mark Safari onboarding / protection test success;
- prove Private Browsing automatically;
- change System Website Filtering behavior.

Follow-up app-side validation is recorded as **SAFARI-PROTECTION-FUNCTIONAL-VALIDATION-1** below.

---

## Safari protection functional validation (17 July 2026)

| Field | Value |
|-------|-------|
| Branch | `feat/safari-protection-functional-validation` |
| Feature | App-side pending-test store + setup UI + query-marker validation for the existing Safari protection test artifact |
| Classification | **SAFARI-PROTECTION-FUNCTIONAL-VALIDATION-1** |
| Device | Physical iPhone |
| Persistent store | `SafariProtectionTestStore` on `UserDefaults.standard` (app-only; not App Group) |
| TTL | **5 minutes** for a pending attempt |
| Query marker | `heal://safe-place?source=safariProtectionTest` |
| Opener | `UIApplication.shared.open` of the exact test URL via the system default URL handler (not guaranteed to be Safari) |

### Physical-device evidence

| Case | Result |
|------|--------|
| Safari as default browser | Test → waiting → dedicated Safari test page → Open Safe Place → Heal Safe Place → setup UI showed **passed previously** |
| Other default browser | Other browser opened; Heal stayed **waiting**; exact test URL shown and selectable; manual open of that URL in Safari within TTL completed the test successfully |
| Production blocking isolation | Production-blocked Safari domain still opened Safe Place; normal `heal://safe-place` did **not** create a new functional-test pass |
| Expired attempt | Test deep link after TTL still opened Safe Place; attempt **not** marked passed; UI reported **expired** |
| Cold start | Force-quit while pending; Safari return within TTL reopened Heal, showed Safe Place, and persisted the functional-test pass |
| Shield regression (standalone) | Custom Heal shield appeared; Safe Place button opened Heal; Safe Place appeared; Shield handoff consumed normally |
| Unexpected product behavior | None observed |

Production adult-domain hostnames used for production-block checks are not recorded here.

### Ownership and routing conclusions

1. `SafariProtectionTestStore` is the only persistent source of truth for the functional-test attempt/result.
2. `SpikeAppState` routes `heal://safe-place` and may call the store; it does not own duplicate writable test-session state.
3. Query-marker validation marks passed only when a non-expired pending attempt exists.
4. Normal production `heal://safe-place` callbacks open Safe Place and never mark the Safari functional test passed.
5. Safe Place still opens for valid test, expired test, and unrelated accepted Safe Place callbacks.
6. Safari deep-link Safe Place entry does **not** consume Shield App Group handoff state (`openedFromShieldHandoff` guard).
7. A previous pass is **historical validation**, not proof that Safari protection is still currently configured.

### Default-browser limitation

Opening the HTTPS test URL uses the system default URL handler. If another browser opens, the user must complete the same test URL in Safari (where Heal’s Safari Web Extension runs) within the five-minute window. Heal does not detect which browser opened.

### Device observation — generic shield under debugger

While the main app was attached to the Xcode debugger, the device showed Apple’s generic shield with an OK button. After stopping the debugger and launching the installed app normally, the custom Heal shield appeared and Shield → Safe Place worked. This is a **device/debug observation**, not a documented platform guarantee.

### Scope boundary for this milestone

This milestone validates end-to-end functional Safari protection in normal Safari using the existing test artifact. It does **not**:

- prove Private Browsing automatically;
- change System Website Filtering;
- change production domain-list / DNR coverage;
- claim the opener always launches Safari;
- treat a past pass as live configuration proof.

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
- Safari Web Extension + Managed Settings `.specific` coexistence (**COEXIST-SPECIFIC-1**, 15 July 2026)
- Safari Web Extension + Managed Settings `.auto` coexistence with explicitly supplied domain (**COEXIST-AUTO-1**, 15 July 2026)
- Safari Web Extension + Managed Settings `.auto()` classifier-only coexistence (**COEXIST-AUTO-CLASSIFIER-1**, 15 July 2026)
- Safari broad website-access permission model (**SAFARI-PERMISSION-ALL-1**, 16 July 2026)
- Safari full static DNR capacity (**SAFARI-DNR-CAPACITY-FULL-1**, 16 July 2026; 76,743 rules including `example.com`)
- Production Safari domain list from verified-license sources (**SAFARI-DOMAIN-LIST-PROD-1**, 16 July 2026; 63,311 rules)
- Safari Extension onboarding foundation: enablement query + open extension settings (**SAFARI-ONBOARDING-FOUNDATION-1**, 16 July 2026)
- Safari protection test artifact: path-specific test URL → dedicated test page → Safe Place deep link (**SAFARI-PROTECTION-TEST-ARTIFACT-1**, 17 July 2026)
- Safari protection functional validation: pending store, query marker, default-browser fallback, cold start, Shield ownership guard (**SAFARI-PROTECTION-FUNCTIONAL-VALIDATION-1**, 17 July 2026)

### Architecture conclusion (coexistence spike)

- Safari: Heal-controlled block page and Safe Place button when the extension covers the domain.
- Chrome and other affected browsers: Apple generic Managed Settings restriction via `.auto()`.
- Heal must maintain its own Safari domain coverage because Apple’s classifier list is not exposed to the extension.

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
- Automatic adult-category blocking at production scale beyond the verified-license static list
- Remote DNR rule updates
- Automatic inactive-domain cleanup

## Evidence and Remaining Uncertainty

**Evidence:** Real-iPhone passes for Milestone J primary path and Milestone K edge cases documented above on iPhone Air, iOS 26.5.1, Xcode 26.6, July 13, 2026.

**Remaining uncertainty:**

- Whether `openParentalControlsApp` and handoff behavior remain reliable on untested OS builds and hardware
- Apple approval requirements and timeline for Family Controls distribution
- Whether ManagedSettings shield persistence policies change across OS updates
- Appropriate product fallback if `openParentalControlsApp` fails on supported devices in the field
- Whether stale-marker rejection behaves as implemented when a marker is actually older than five minutes on device
