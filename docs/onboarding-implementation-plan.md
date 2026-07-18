# Onboarding Implementation Plan

Approved architecture and milestone sequence for Heal’s minimal production-oriented onboarding flow.

This document is the implementation plan for milestones M1–M7. It does not rewrite historical spike validation records.

---

## 1. Current product gap

Validated building blocks already exist (Screen Time auth, Safari extension enablement detection, extension settings deep link, manual All Websites / Private Browsing instructions, Safari functional protection test, Safe Place routing, System Website Filtering enable/disable, and required Safari-before-system-filter ordering guidance).

They are still spike-oriented and split across `SetupView`, `SafariExtensionSetupSection`, `WebsiteFeasibilityView`, `SpikeAppState`, `SafariProtectionTestStore`, and `SystemWebFilteringService`.

Critical navigation gap: `ContentView` currently treats Screen Time authorization as the only hard root gate. `SetupView` (including Safari setup UI) appears only when authorization is **not** approved. After approval, the user lands on spike `AppSelectionView`, and System Website Filtering lives only inside debug/feasibility UI. There is no persisted onboarding completion and no dedicated onboarding ownership model.

---

## 2. Goals and non-goals

### Goals

Guide a new user through the smallest clean onboarding path:

1. Explanation
2. Screen Time authorization
3. Safari extension enablement
4. Manual All Websites permission confirmation
5. Manual Private Browsing enablement confirmation
6. Functional Safari protection test
7. Optional System Website Filtering activation (explicit consent)
8. Completion

Establish clear ownership, persistence, and root navigation before polishing visuals.

### Non-goals

- Final brand / visual design
- Detecting All Websites or Private Browsing via Apple APIs (not available)
- Treating a historical functional-test pass as live configuration proof
- Auto-enabling System Website Filtering
- Replacing Safe Place, shield handoff, or production Safari DNR rules in onboarding milestones
- Making `WebsiteFeasibilityView` part of product onboarding
- Persisting a writable `currentStep`

---

## 3. State classification

| Kind | Meaning | Examples | Source of truth |
|------|---------|----------|-----------------|
| **Directly detectable** | Readable from Apple / system APIs | Screen Time authorization; Safari extension enabled/disabled; System Website Filtering enabled/cleared | Existing services (`AuthorizationService`, `SafariExtensionService`, `SystemWebFilteringService`) |
| **Manually confirmed** | User asserts a setting Heal cannot detect | All Websites; Private Browsing | Dedicated onboarding persistence (later milestones) |
| **Functionally validated** | End-to-end proof via test artifact | Safari protection functional test pending / passed / expired | `SafariProtectionTestStore` |
| **Historical and potentially stale** | Was true earlier; may no longer match device config | Past functional pass; past manual confirms; onboarding completed while extension later disabled | Persisted timestamps/flags + live re-check of detectable state |

---

## 4. Ownership and single sources of truth

| Concern | Owner | Must not own |
|---------|-------|--------------|
| Onboarding completion and (later) manual confirms / SWF consent-skip | **`OnboardingProgress`** | Technical Apple API details; functional-test session writes |
| Screen Time auth | `AuthorizationService` (+ thin app orchestration where already used) | Onboarding step machine |
| Safari enablement query / open settings | `SafariExtensionService` (stateless) | Onboarding persistence |
| Functional test pending / pass / expire | `SafariProtectionTestStore` | UI routing ownership |
| Open test URL | `SafariProtectionTestOpener` | Persistence |
| System Website Filtering enable/disable/read | `SystemWebFilteringService` | Onboarding completion |
| Safe Place interrupt routing | `SpikeAppState` | Onboarding progress |
| Spike app-shield / one-app selection | `SpikeAppState` + existing services | Product Safari onboarding flags |
| Views | Display + trigger actions only | Persistence / Apple API wrappers |

### Approved decision: `SpikeAppState`

`SpikeAppState` must **not** own onboarding progress. It continues to own spike orchestration and Safe Place routing, and may call technical stores/services without duplicating their writable data.

### Avoid duplicate writable state

- One owner writes each persisted product flag.
- Views may hold ephemeral display copies of fetched live state; they must not become a second persistence path.
- Existing technical services/stores remain their own sources of truth.

---

## 5. Root navigation priority

Effective root order:

1. Initial system refresh / loading state
2. Pending Safe Place entry (**highest product interrupt**)
3. Incomplete onboarding → onboarding shell
4. Existing post-onboarding application flow (currently spike `AppSelectionView` when authorized, otherwise existing setup/auth UI)

Safe Place must interrupt every other root flow. When dismissed, the app returns naturally to the onboarding shell if onboarding is incomplete.

---

## 6. Persistence policy

| Data | Persist? | Owner / location | Notes |
|------|----------|------------------|-------|
| `hasCompletedOnboarding` | Yes (M1) | `OnboardingProgress` / app-local `UserDefaults` | Launch gate |
| `hasAcknowledgedIntroduction` | Yes (M2) | `OnboardingProgress` / app-local `UserDefaults` | Explanation-step acknowledgement only |
| Writable `currentStep` | **No** | — | Visible step is derived from persisted progress + live technical state |
| Manual All Websites confirmation | Yes (M3) | `OnboardingProgress` / app-local `UserDefaults` | Manual assert only — not detectable |
| Manual Private Browsing confirmation | Yes (M3) | `OnboardingProgress` / app-local `UserDefaults` | Manual assert only — not detectable |
| SWF consent / skip choice | Later | `OnboardingProgress` | Actual on/off remains ManagedSettings via service |
| Functional test timestamps | Already | `SafariProtectionTestStore` | Historical pass ≠ live proof |
| Extension enabled | No durable product write | Fetch live via `SafariExtensionService` | Ephemeral presentation state only |
| Screen Time auth | System | Refresh live | |
| System Website Filtering on/off | System (ManagedSettings) | `SystemWebFilteringService` | |

### Derived visible step

Do **not** persist a writable `currentStep`. The visible onboarding step is derived from:

- persisted onboarding progress flags (completion, introduction acknowledgement, manual confirms; later consent), plus
- live technical state from existing services/stores.

#### M4 derived-step decision

While `hasCompletedOnboarding == false`, `OnboardingFlowView` derives the visible step as:

1. If `hasAcknowledgedIntroduction == false` → explanation step
2. Else if Screen Time authorization is not approved (`SpikeAppState.isAuthorizationApproved == false`) → Screen Time authorization step
3. Else if Safari extension is not currently detected as enabled (live `SafariExtensionEnablementModel.isEnabled == false`) → Safari extension enablement step
4. Else if `hasConfirmedSafariAllWebsitesAccess == false` → All Websites manual confirmation step
5. Else if `hasConfirmedSafariPrivateBrowsing == false` → Private Browsing manual confirmation step
6. Else if `SafariProtectionTestStore.displayStatus() != .passed` → Safari functional protection test step
7. Else → temporary M4 checkpoint (“Safari protection test passed / SWF consent next in M5”)

A historical manual confirmation must **not** bypass the live extension-enabled requirement. If the extension is later disabled while onboarding remains incomplete, the derived flow returns to the extension enablement step.

A historical functional-test pass advances past the test step for onboarding progression but must **not** be presented as live configuration proof. Approving Screen Time, enabling the extension, confirming manual permissions, or passing the functional test does **not** set `hasCompletedOnboarding`. Full onboarding remains incomplete until a later milestone (or the temporary test complete control).

---

## 7. Safe Place interruption behavior

- `SpikeAppState.pendingSafePlaceEntry` remains the interrupt signal.
- URL parsing, query-marker functional-test pass marking, and shield handoff consume semantics stay unchanged.
- Safe Place opens over onboarding and over the post-onboarding root.
- Dismiss returns to whatever root gate applies next (incomplete onboarding → shell; complete → post-onboarding flow).
- Because onboarding does not persist `currentStep`, resume returns to the onboarding shell and re-derives the visible step from persisted flags + live authorization + live Safari enablement + functional-test store status. Correct for M1–M4.

---

## 8. System Website Filtering consent and ordering constraints

- Present only after Safari setup prerequisites are satisfied (later milestones: detectable enable + manual confirms + functional validation policy).
- Explicit user consent: Enable or Skip — never auto-enable.
- Warn that on tested devices an active system web filter may grey out Safari extension settings (device observation, not an API guarantee).
- Easy disable path required.
- No automatic re-enable without a new user action.
- `WebsiteFeasibilityView` must not become the product consent surface.

---

## 9. Reuse versus retirement of spike UI

| Item | Plan |
|------|------|
| `SafariExtensionService`, `SafariProtectionTestStore`, `SafariProtectionTestOpener`, `SystemWebFilteringService`, `AuthorizationService` | Reuse as technical foundations |
| Safe Place routing in `SpikeAppState` | Reuse; do not move test-pass ownership |
| `SafariExtensionSetupSection` | Split / slim into onboarding steps in later milestones |
| `SetupView` auth UI | Fold into onboarding Screen Time step later |
| `WebsiteFeasibilityView` | **Remain spike/debug-only** |
| `AppSelectionView` | Remain temporary post-onboarding root for now |
| Dual product + feasibility Safari/SWF UI | Demote feasibility to debug-only over M7; avoid two primary flows |

---

## 10. Milestone sequence M1–M7

| Milestone | Responsibility |
|-----------|----------------|
| **M1** | `OnboardingProgress` + root navigation gate + minimal onboarding shell; persist completion only |
| **M2** | Explanation + Screen Time steps |
| **M3** | Safari enable + open settings + manual All Websites / Private Browsing confirms |
| **M4** | Functional Safari protection test wired into onboarding; Safe Place dismiss returns to shell |
| **M5** | Optional SWF consent/skip + warning + disable; blocked until Safari prerequisites |
| **M6** | Completion hardening + minimal post-completion repair when extension is disabled |
| **M7** | Demote spike duplication; keep feasibility debug-only |

Each milestone stops before commit, requires device testing, and avoids final visual design.

---

## 11. Device-test requirements per milestone

### M1

1. Fresh/incomplete state launches into onboarding
2. Marking onboarding complete routes to the existing post-onboarding root
3. Completion survives force-quit and relaunch
4. Safe Place entry interrupts onboarding
5. Dismissing Safe Place returns to onboarding when incomplete
6. Safe Place entry interrupts the completed/post-onboarding root
7. Existing Screen Time, app-selection, Safari-test, and shield paths show no obvious regression — post-onboarding `AppSelectionView` / `SetupView` must render with no injected overlay or inset; existing controls must remain fully reachable without adding scrolling to those views
8. To re-test incomplete onboarding after marking complete: delete and reinstall the app (M1 reset procedure). There is no in-app Reset control on the post-onboarding root

### M2

1. Fresh/reset state opens the explanation step
2. Continue advances to the Screen Time step
3. Introduction acknowledgement survives force-quit and relaunch
4. Authorization request opens the Apple authorization flow
5. Approval automatically advances to the M2 checkpoint
6. Denial or failure remains recoverable and allows retry
7. Authorization state remains approved after relaunch
8. Revoking authorization returns incomplete onboarding to the Screen Time step
9. Safe Place interrupts the explanation step and the Screen Time step
10. Dismissing Safe Place returns to the correct derived onboarding step
11. Temporary completion/reset controls still behave as documented
12. Existing app-selection, Safari-test, and shield paths remain reachable after temporary full completion

### M3

1. After Screen Time approval, incomplete onboarding shows the Safari extension enablement step when the extension is not detected as enabled
2. Open Safari Extension Settings launches the existing settings flow
3. Enabling the extension and returning (or foregrounding) advances past enablement only when live detection reports enabled
4. Disabling the extension while onboarding is incomplete returns the derived flow to the enablement step even if manual confirms were previously recorded
5. All Websites confirmation requires an explicit user action and persists across force-quit and relaunch
6. Private Browsing confirmation requires an explicit user action and persists across force-quit and relaunch
7. Manual confirmation copy states that Apple does not provide an API to verify those settings
8. User cannot reach the M3 checkpoint without live enablement + both manual confirms
9. Safe Place interrupts Safari onboarding steps; dismiss returns to the correct derived step
10. Temporary reset clears introduction acknowledgement, both manual confirms, and completion — and does not revoke Screen Time, disable the extension, alter Safari system settings, alter functional-test state, or alter System Website Filtering
11. Temporary completion still routes to the existing post-onboarding root for regression testing
12. Existing spike Safari functional-test controls outside onboarding remain unchanged (M4 wires the product path)

### M4

1. After M3 prerequisites, incomplete onboarding shows the Safari functional protection test step when the store status is not `.passed`
2. Starting the test records a pending attempt via `SafariProtectionTestOpener` / `SafariProtectionTestStore` and opens the test URL
3. Completing the test URL in Safari with the functional-test source marker marks pass only when a valid pending attempt exists
4. Production `heal://safe-place` without the test source marker does not false-pass
5. Expired pending attempts become `.expired` and do not pass; retry starts a new pending attempt
6. Waiting state shows the manual test URL for non-Safari default browsers
7. Safe Place remains the highest-priority root interrupt during the test
8. Dismissing Safe Place while onboarding is incomplete remounts the onboarding shell; `OnboardingFlowView.onAppear` reloads functional-test status and routing is re-derived (waiting, expired, test, or M4 checkpoint after pass)
9. A valid pass advances to the temporary M4 checkpoint without setting `hasCompletedOnboarding`
10. Temporary reset still does not clear functional-test store state
11. Spike/setup functional-test controls continue to reuse the same store/opener
12. Existing app-selection and shield paths remain reachable after temporary full completion

### M5

- SWF blocked until Safari prerequisites
- Enable / disable / skip
- No auto re-enable
- Greyed-settings warning copy present

### M6

- Completed users land on post-onboarding root
- Disabled extension after completion surfaces repair, not silent success
- SWF remains optional

### M7

- Product path only through onboarding
- Feasibility still reachable from spike/debug entry
- No duplicate writable onboarding state in feasibility UI

---

## 12. Architectural risks and guardrails

1. Do not put onboarding progress on `SpikeAppState`.
2. Do not persist writable `currentStep`; derive the visible step later.
3. Do not duplicate functional-test or extension writable state in onboarding.
4. Historical functional pass must not be presented as live protection proof.
5. SWF before Safari setup can trap users (greyed extension settings on tested device).
6. Keeping product onboarding and Website Feasibility both primary risks double UI and confused testers.
7. Auth revoke after completion needs repair behavior (later), not accidental full silent reset of unrelated state.
8. Follow `docs/AI-Coding-Guardrails.md`: views display/trigger; services/stores own technical operations; stop on ownership ambiguity.

### M1 ownership note (implementation)

- **Constructs / retains:** `HealApp` creates one `OnboardingProgress` with `@State` at app scope (same observation style as `SpikeAppState`; deployment target supports `@Observable`).
- **Reads:** `ContentView` for root routing only; `OnboardingFlowView` for display.
- **Mutates:** temporary M1 completion control in `OnboardingFlowView` calls `markOnboardingCompleted()`. `ContentView` does not inject overlays, insets, or reset controls into the post-onboarding root.
- **M1 incomplete-state reset procedure:** delete and reinstall the app (clears app-local `UserDefaults`, including `onboarding.hasCompletedOnboarding`). Do not add a post-onboarding Reset control that alters `AppSelectionView` / `SetupView` layout.
- **Persistence:** model methods write app-local `UserDefaults`; in-memory property is the single observable reflection of that value, not a second independent store.

### M2 ownership and implementation note

- **`OnboardingProgress` owns only:**
  - `hasAcknowledgedIntroduction` (`onboarding.hasAcknowledgedIntroduction`)
  - `hasCompletedOnboarding` (`onboarding.hasCompletedOnboarding`)
- **Does not own:** Screen Time authorization status, Safari flags, functional-test state, System Website Filtering state, or a writable `currentStep`.
- **Screen Time ownership / data flow:**

```text
System authorization
    ↓ refresh/request
AuthorizationService / SpikeAppState
    ↓ observable live status
OnboardingFlowView
    ↓ derived visible step
Explanation | Screen Time | M2 pending state
```

- **Views trigger, do not persist:** Explanation Continue calls `OnboardingProgress.acknowledgeIntroduction()`. Screen Time Enable/Retry calls `SpikeAppState.requestAuthorization()` (existing path → `AuthorizationService`). No direct `UserDefaults` or FamilyControls writes from views.
- **Relaunch:** Introduction acknowledgement is reloaded from `UserDefaults` in `OnboardingProgress.init`. Authorization is refreshed via existing `SpikeAppState.refreshSystemState()` / `refreshAuthorizationStatus()` — never from a persisted auth Boolean in onboarding.
- **Revocation while incomplete:** If authorization is later not approved, derived step returns to Screen Time. No stale onboarding auth flag can override system state.
- **Temporary M2 checkpoint:** Shown when introduction is acknowledged and live auth is approved. Full onboarding stays incomplete (`hasCompletedOnboarding` unchanged).
- **Temporary test controls (onboarding shell only):** See M3 note — reset now clears all `OnboardingProgress` flags including M3 manual confirms; it still does not revoke Screen Time authorization.
- **Reuse vs duplication:** Auth request/refresh semantics remain in `SpikeAppState` / `AuthorizationService`. Status labels and request-button presentation are shared via `ScreenTimeAuthorizationSection`. `SetupView` remains the post-onboarding / incomplete-auth root UI.

### M3 ownership and implementation note

- **`OnboardingProgress` owns only:**
  - `hasAcknowledgedIntroduction` (`onboarding.hasAcknowledgedIntroduction`)
  - `hasConfirmedSafariAllWebsitesAccess` (`onboarding.hasConfirmedSafariAllWebsitesAccess`)
  - `hasConfirmedSafariPrivateBrowsing` (`onboarding.hasConfirmedSafariPrivateBrowsing`)
  - `hasCompletedOnboarding` (`onboarding.hasCompletedOnboarding`)
- **Does not own:** Screen Time authorization status, Safari extension enabled Boolean, functional-test state, System Website Filtering state, or a writable `currentStep`.
- **Safari enablement ownership / data flow:**

```text
SFSafariExtensionManager (live)
    ↓ fetchState / openExtensionSettings
SafariExtensionService (stateless technical owner)
    ↓
SafariExtensionEnablementModel (ephemeral presentation state)
    ↓
SafariExtensionEnablementSection / OnboardingFlowView
    ↓ derived visible step (with OnboardingProgress manual confirms)
Enablement | All Websites confirm | Private Browsing confirm | (M4 continues)
```

- **Open-settings action:** Views call `SafariExtensionEnablementModel.openSettings()` → `SafariExtensionService.openExtensionSettings()`. No second open-settings implementation.
- **Persisted manual confirmations:** Explicit buttons call `OnboardingProgress.confirmSafariAllWebsitesAccess()` / `confirmSafariPrivateBrowsing()`. Presented as user assertions, not technical verification.
- **Live refresh:** `OnboardingFlowView` refreshes Safari enablement when introduction is acknowledged and Screen Time is approved — on appear, on foreground (`scenePhase == .active`), and when the enablement step becomes visible. `SafariExtensionEnablementModel.refresh()` cancels any in-flight refresh to avoid overlapping tasks. Last known non-checking state is kept while refreshing so later steps do not flash away.
- **SpikeAppState:** Continues to own Screen Time orchestration and Safe Place routing only. Does **not** own Safari enablement.
- **Reuse:** `SafariExtensionSetupSection` (spike/setup + feasibility) composes `SafariExtensionEnablementSection` and `SafariProtectionTestSection`.

### M4 ownership and implementation note

- **Functional-test ownership / data flow:**

```text
SafariProtectionTestOpener.startAndOpen()
    ↓ pending write
SafariProtectionTestStore (UserDefaults)
    ↑ markPassedIfPendingValid (only with source=safariProtectionTest)
SpikeAppState.handleIncomingURL
    ↓ pendingSafePlaceEntry
Safe Place (highest-priority root interrupt; ContentView unmounts onboarding)
    ↓ dismiss → remount incomplete onboarding shell
OnboardingFlowView.onAppear reloads store status → derived step
Protection test | M4 checkpoint
```

- **Does not own in `OnboardingProgress`:** functional-test pending/pass/expiry timestamps (remain in `SafariProtectionTestStore`).
- **Pass rules unchanged:** only `heal://safe-place?source=safariProtectionTest` with a valid non-expired pending attempt marks pass. Plain `heal://safe-place` opens Safe Place without passing. `markPassedIfPendingValid` consumes the pending attempt once. The fixed source marker confirms a currently valid pending attempt exists; it does not cryptographically correlate a callback with a specific prior attempt.
- **Derived routing:** After M3 prerequisites, `protectionTestStatus != .passed` → protection-test step; `.passed` → temporary M4 checkpoint. Ephemeral `protectionTestStatus` is initialized from `SafariProtectionTestStore.displayStatus()` and refreshed on appear, foreground, and entering the test step. Safe Place dismiss remounts the incomplete onboarding shell; remount `onAppear` reloads store status and re-derives the step.
- **UI reuse:** `SafariProtectionTestSection` is shared by onboarding and spike/setup. Views trigger `SafariProtectionTestOpener`; they do not write pass/expiry directly.
- **Temporary M4 checkpoint:** Shown when M3 prerequisites are satisfied and the functional test has passed. Full onboarding stays incomplete (`hasCompletedOnboarding` unchanged). Past pass is not presented as live configuration proof.
- **Temporary test controls:** unchanged — reset does **not** clear `SafariProtectionTestStore`.
- **Remaining M5 work:** Optional System Website Filtering consent/skip + warning + disable; blocked until Safari prerequisites including functional validation policy.

### Deferred M3 cleanup

These items do **not** block M3. They must **not** be implemented during M4 or M5 unless a concrete bug appears. **M7** is the default review point.

1. **Safari refresh triggers in `OnboardingFlowView`** — Re-evaluate whether all three are still needed: `onAppear`, foreground activation, and transition into the Safari enablement step. Current status: not a correctness bug; overlapping refreshes are cancelled safely. Revisit only if lifecycle complexity grows or duplicate queries become observable.

2. **`SafariExtensionEnablementSection.refreshesWithLifecycle`** — Re-evaluate whether the flag can be simplified after product onboarding and spike/debug flows are consolidated in M7. Current status: not an ownership bug; the flag avoids duplicate lifecycle refresh ownership. Defer until M7 cleanup to avoid premature refactoring.

Do not treat merging the two per-surface `SafariExtensionEnablementModel` instances as cleanup; that ownership is currently intentional.
