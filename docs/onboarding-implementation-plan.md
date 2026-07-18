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
| Manual All Websites / Private Browsing confirms | Later | `OnboardingProgress` | Not detectable |
| SWF consent / skip choice | Later | `OnboardingProgress` | Actual on/off remains ManagedSettings via service |
| Functional test timestamps | Already | `SafariProtectionTestStore` | Historical pass ≠ live proof |
| Extension enabled | No durable product write | Fetch live | |
| Screen Time auth | System | Refresh live | |
| System Website Filtering on/off | System (ManagedSettings) | `SystemWebFilteringService` | |

### Derived visible step

Do **not** persist a writable `currentStep`. The visible onboarding step is derived from:

- persisted onboarding progress flags (completion, introduction acknowledgement; later manual confirms / consent), plus
- live technical state from existing services/stores.

#### M2 derived-step decision

While `hasCompletedOnboarding == false`, `OnboardingFlowView` derives the visible step as:

1. If `hasAcknowledgedIntroduction == false` → explanation step
2. Else if Screen Time authorization is not approved (`SpikeAppState.isAuthorizationApproved == false`) → Screen Time authorization step
3. Else → temporary M2 checkpoint (“Screen Time ready / Safari setup next”)

Approving Screen Time does **not** set `hasCompletedOnboarding`. Full onboarding remains incomplete until a later milestone (or the temporary test complete control).

---

## 7. Safe Place interruption behavior

- `SpikeAppState.pendingSafePlaceEntry` remains the interrupt signal.
- URL parsing, query-marker functional-test pass marking, and shield handoff consume semantics stay unchanged.
- Safe Place opens over onboarding and over the post-onboarding root.
- Dismiss returns to whatever root gate applies next (incomplete onboarding → shell; complete → post-onboarding flow).
- Because onboarding does not persist `currentStep`, resume returns to the onboarding shell and re-derives the visible step from persisted flags + live authorization. Correct for M1/M2.

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

- Extension enable/disable refreshes on foreground
- Manual confirms persist across relaunch
- Cannot skip ahead of detectable enable + confirms

### M4

- Full functional pass path
- Expired pending attempt
- Non-Safari default browser manual URL path
- Production `heal://safe-place` does not false-pass the test
- Safe Place dismiss returns to onboarding shell while incomplete

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
- **Temporary test controls (onboarding shell only):**
  - `Mark Onboarding Complete (Temporary Test)` → `markOnboardingCompleted()` for post-onboarding regression routing.
  - `Reset Onboarding Progress (Temporary Test)` → `resetTemporaryTestingState()`, which clears **both** OnboardingProgress flags (introduction + completion). Does **not** revoke or change Screen Time authorization.
- **Reuse vs duplication:** Auth request/refresh semantics remain in `SpikeAppState` / `AuthorizationService`. Status labels and request-button presentation are duplicated locally in `OnboardingFlowView` rather than extracting from `SetupView`, to avoid a broad SetupView refactor in M2. `SetupView` remains the post-onboarding / incomplete-auth root UI.
- **Remaining M3 work:** Safari extension enablement, open settings, manual All Websites / Private Browsing confirms; replace the temporary M2 checkpoint with the Safari step sequence.
