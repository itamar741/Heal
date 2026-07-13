# Feasibility Research Plan

## 1. Overview

**Goal:** Determine whether the core product can be built using Apple's Screen Time APIs:

- FamilyControls
- ManagedSettings
- ManagedSettingsUI
- DeviceActivity

The key question is:

Can an iOS app reliably block or shield addictive apps/domains/categories and guide the user into a Safe Place experience using only Apple's Screen Time-related APIs?


## Core Feasibility Questions

**Goal:** Define the exact assumptions that must be proven before building the product.

### Main Questions
- Can users select apps, app categories, and web domains to restrict?
- Can the app shield those targets reliably?
- Can the shield experience be customized enough for an addiction-intervention product?
- Can the shield guide the user into the app's Safe Place?
- Can this work for an individual adult user, not only a parent-child setup?
- What requires Apple approval before TestFlight or App Store distribution?
- What works in development on a real iPhone before Apple grants distribution approval?

### Research / Validation Needed

- Validate current Apple documentation for Screen Time frameworks.
- Confirm iOS version requirements.
- Confirm development versus distribution entitlement behavior.
- Test on a real iPhone as early as possible.
- Identify API limitations that affect the target user flow.

### Expected Output

A feasibility decision:

- Viable as designed
- Viable with UX compromises
- Technically possible but high App Store risk
- Not viable with current public APIs

Most likely early hypothesis: viable with UX compromises for broader target types (categories, domains) and scheduling. The first spike should validate the one-app shield flow using `ShieldActionResponse.openParentalControlsApp` before assuming those compromises are needed.

## 2. Framework Capability Review

### 2.1 FamilyControls

**Goal**
Understand what FamilyControls contributes to the product.

What It Appears To Do
FamilyControls is the authorization and selection layer. It allows the user to grant Screen Time access and select restricted targets through Apple-controlled UI.

Likely relevant pieces:
- User authorization through AuthorizationCenter
- Individual user authorization
- App/category/domain selection through FamilyActivityPicker
- Opaque tokens representing selected apps, domains, or categories

Main Questions
- Can the app use individual authorization for a self-control/addiction-intervention use case?
- Can the user select specific apps?
- Can the user select app categories?
- Can the user select web domains?
- Are selected targets exposed only as opaque tokens?
- Can those selections be stored locally and reused?

Research / Validation Needed
- Confirm support for FamilyControlsMember.individual.
- Confirm picker behavior for apps, categories, and domains.
- Confirm whether selected tokens can be persisted.
- Confirm whether the app ever receives human-readable app/domain names.
- Confirm privacy limitations around what the app can inspect.

Expected Output
A clear answer to:

Can the user choose what they want protected from inside the app?


### 2.2 ManagedSettings

**Goal**
Understand how blocking and shielding actually work.

What It Appears To Do
ManagedSettings is the enforcement layer. It can apply Screen Time-style restrictions using a ManagedSettingsStore.

Likely relevant capabilities:
- Shield selected applications
- Shield selected application categories
- Shield selected web domains
- Apply restrictions through opaque tokens from FamilyControls
- Customize shield appearance through ManagedSettingsUI

Main Questions
- Can selected apps be shielded immediately?
- Can selected categories be shielded?
- Can selected domains be shielded?
- Can shields stay active until removed by the app?
- Can shields be scheduled or conditionally activated?
- Can multiple shield stores or groups be used for different intervention modes?

Research / Validation Needed
- Validate app shielding behavior.
- Validate category shielding behavior.
- Validate web domain shielding behavior.
- Confirm how persistent shields are across app launches, reboots, and authorization changes.
- Confirm how the app clears or updates shield settings.
- Confirm whether shielded domains behave consistently across supported system surfaces.

Expected Output
A blocking capability matrix:

| Target Type | Can Select | Can Shield | Reliability | Notes |
|-------------|------------|------------|-------------|-------|
| Specific apps | TBD | TBD | TBD | Validate on device |
| App categories | TBD | TBD | TBD | Validate category behavior |
| Web domains | TBD | TBD | TBD | Validate limitations |
| Full URL paths | Likely no | Likely no | Not expected | Avoid relying on this |


### 2.3 ManagedSettingsUI / Shield Experience

**Goal**
Understand what the user sees after attempting to open a restricted target.

What It Appears To Do
ManagedSettingsUI allows customization of shield screens shown when a user tries to access restricted content.

Likely relevant extension targets:
- Shield Configuration extension
- Shield Action extension

Main Questions
- How much can the shield UI be customized?
- Can the shield show supportive intervention copy?
- Can the shield show custom buttons?
- What button actions are allowed?
- Can the shield directly open the main app?
- Can the shield identify which target triggered it?

Research / Validation Needed
- Confirm available shield configuration fields:
  - title
  - subtitle
  - primary button
  - secondary button
  - icon/visual customization
- Confirm available shield action responses.
- Validate `ShieldActionResponse.openParentalControlsApp` as the primary Safe Place entry path on a real supported iPhone.
- Validate whether a shield action can write local state via App Groups before the main app opens.

Expected Output
A shield UX capability summary.

Earlier assumption:
Opening the main app from a shield action was considered uncertain.

Final spike assumption:
The primary spike should validate `ShieldActionResponse.openParentalControlsApp` on a real supported iPhone as the main Safe Place entry path.

Notification or manual fallback should only be considered if `openParentalControlsApp` fails during real-device testing. It is not part of the first spike.


### 2.4 DeviceActivity

**Goal**
Understand whether the app needs DeviceActivity for MVP or only later.

What It Appears To Do
DeviceActivity can monitor usage during schedules and trigger extension code when activity thresholds are reached.

Relevant pieces:
- DeviceActivitySchedule
- DeviceActivityMonitor
- Device Activity Monitor extension
- Device Activity Report extension

Main Questions
- Is DeviceActivity required for always-on shielding?
- Can it detect when a blocked target is attempted?
- Can it trigger an intervention event?
- Can it schedule different restriction windows?
- Can it support future features like "high-risk time blocks"?

Research / Validation Needed
- Validate whether MVP can use ManagedSettings directly without complex monitoring.
- Validate whether DeviceActivity can trigger extension callbacks reliably.
- Confirm threshold behavior.
- Confirm background execution limits.
- Confirm what reports expose without compromising privacy.

Expected Output
A recommendation:
- Use DeviceActivity in MVP only if needed for scheduling or event triggers.
- Keep MVP focused on manual/always-on shielding if that proves simpler.
- Add scheduled/high-risk interventions later if the core shield flow works.


## 3. Target Flow Validation

### 3.1 Desired Flow

**Goal**
Validate each step of the intended product flow.

User Attempts Restricted App
  -> System Shows Shield
  -> User Chooses Shield Action
  -> Safe Place Entry Path (via `openParentalControlsApp`)
  -> Main App Safe Place
  -> One Supportive Video
  -> Urge Passed / Another Video / Need Help / Close

Note: The first spike validates only one specific selected app. Categories, domains, and web filtering are deferred until the one-app flow works.

Main Questions
- Which parts are fully supported by public APIs?
- Which parts require compromise?
- Which parts are impossible or unreliable?

Research / Validation Needed
Each step should be validated independently for the first spike (one specific app only):

Step                              | Feasibility Status  | Validation Needed
----------------------------------|---------------------|----------------------------------
User selects one specific app     | Likely supported    | Test FamilyActivityPicker (app only)
App shields selected app          | Likely supported    | Test ManagedSettingsStore
User sees shield                  | Supported           | Test shield extensions
Shield opens Safe Place           | Primary path to test| Validate `openParentalControlsApp` on device
App plays one video               | Supported           | Standard app functionality
User chooses outcome action       | Supported           | Standard app functionality

Expected Output
A step-by-step feasibility map for the one-app flow, showing where the product path is strong and where fallback UX may be needed only if `openParentalControlsApp` fails.


## Entitlement Feasibility

**Goal**
Determine what can be tested now and what depends on Apple approval.

Main Questions
- Can development builds use Family Controls locally?
- Is distribution approval required for TestFlight?
- Does each app extension need its own approved entitlement?
- How long might approval take?
- How should the product be positioned in the entitlement request?

Research / Validation Needed
- Confirm development entitlement availability.
- Confirm distribution entitlement process.
- Identify all bundle IDs that need approval:
  - main app
  - Shield Configuration extension
  - Shield Action extension
  - Device Activity Monitor extension, if used
  - Device Activity Report extension, if used
- Validate whether TestFlight upload is blocked without distribution entitlement.

Expected Output
An entitlement plan with:
- required capabilities
- required bundle IDs
- development/testing path
- TestFlight/App Store blockers
- recommended entitlement request language

Key early assumption: real-device development testing may be possible before distribution approval, but TestFlight/App Store distribution requires Apple approval.


## Real iPhone Testing Plan

**Goal**
Confirm behavior on actual hardware before designing too much product around untested assumptions.

Main Questions
- Does authorization work on the target iOS version?
- Does selection of one specific app work?
- Does shielding that app happen immediately?
- Does shield customization appear as expected?
- Does `ShieldActionResponse.openParentalControlsApp` open the main app reliably?
- What happens when the user taps shield buttons?
- What happens after reboot, app force-quit, or permission revocation?

Note: Domain selection, category selection, and web filtering are out of scope for the first spike.

Research / Validation Needed
Test on:
- one personal iPhone
- latest stable iOS version
- development build
- Apple Developer account with Family Controls development capability
- minimal app with required Screen Time extension targets

Expected Output
A real-device test report with:
- screenshots
- observed behavior
- unsupported behavior
- bugs or inconsistencies
- revised product assumptions


## 6. Known Likely Limitations

**Goal**
Identify constraints early so the product does not depend on impossible behavior.

Likely Limitations To Validate
- The app likely cannot access full browsing history.
- The app likely cannot inspect exact URLs or page contents.
- Selected apps/domains/categories are represented as opaque tokens.
- Shield UI customization is limited.
- `ShieldActionResponse.openParentalControlsApp` must be validated on a real supported iPhone as the primary Safe Place entry path; notification/manual fallback is only relevant if this path fails.
- Screen Time API behavior may vary between development and distribution builds.
- Apple entitlement approval is a major dependency.

Note for first spike: Category shielding, domain/web filtering, DeviceActivity, scheduled interventions, and notification fallback flows are explicitly out of scope until the one-app shield flow is proven.

Expected Output
A limitation list divided into:
- hard platform limitations
- App Store / entitlement risks
- UX workaround areas
- unknowns requiring device testing


## 7. MVP Technical Spike

**Goal**
Create an implementation-ready plan for the smallest future iOS prototype that proves the riskiest assumption:

Can a Screen Time shield on one specific selected app interrupt the user and route them into the Safe Place experience with minimal friction?

This section is a planning artifact only. It does not include production code and does not require a Mac/Xcode setup yet.

First-Spike Scope Rule
The first technical spike must validate only one specific selected app.

Do not start with:
- app categories
- domains
- web filtering
- DeviceActivity reports
- scheduled interventions
- fallback notification flows

Those should only be tested after the one-app shield flow works.

Main Technical Questions
- Can the app request Screen Time / FamilyControls authorization?
- Can the user select one specific app using FamilyActivityPicker?
- Can the app persist the selected app token locally?
- Can the app apply a shield to that selected app using ManagedSettingsStore?
- Can `ShieldActionResponse.openParentalControlsApp` open the main app and provide a usable Safe Place entry path?
- Can this be tested reliably on a real supported iPhone?

Required Xcode Targets
The technical spike should include only the minimum targets needed to validate the one-app shield-to-Safe-Place flow.

Main iOS App Target
Purpose: Hosts onboarding, Screen Time authorization, single-app selection, shield setup, and the Safe Place screen.

Responsibilities:
- Request FamilyControls authorization for an individual user.
- Present FamilyActivityPicker for one specific app selection.
- Persist the selected app token locally.
- Apply a shield to that app through ManagedSettingsStore.
- Read handoff context from the Shield Action extension.
- Route the user into Safe Place when the app opens after a shield action.

Shield Configuration Extension
Purpose: Defines the intervention/shield screen shown when the user attempts to open the blocked app.

Responsibilities:
- Provide supportive shield title/subtitle.
- Provide a primary action: "Open Safe Place".
- Optionally provide a secondary action such as "Close".
- Keep the shield experience minimal and non-punitive.

Shield Action Extension
Purpose: Handles user button taps from the shield.

Responsibilities:
- Detect primary button press.
- Write a minimal local handoff marker through App Groups.
- Return `ShieldActionResponse.openParentalControlsApp`.
- Avoid complex business logic inside the extension.

Device Activity Monitor Extension
First-spike status: Out of scope.

Defer until after the one-app shield flow is proven. Do not include for scheduled or threshold-based enforcement in the first spike.

Device Activity Report Extension
First-spike status: Out of scope.

Do not include reporting. The first spike validates intervention flow only, not analytics or usage visualization.

Required Entitlements / Capabilities
The future Xcode project should be planned around these capabilities.

Family Controls
Required for:
- main app target
- Shield Configuration extension
- Shield Action extension

Validation item:
Confirm development availability versus distribution approval requirements for every bundle ID.

App Groups
Required for:
- main app target
- Shield Action extension

Purpose:
- Share minimal local handoff context between the shield extension and the main app.
- Avoid backend or network dependency.

Notifications
First-spike status: Out of scope.

Do not include notification-based fallback in the first spike. If `ShieldActionResponse.openParentalControlsApp` fails during real-device testing, notification or manual fallback may be explored in a follow-up spike only.

Associated Domains / Universal Links
First-spike status: Out of scope.

The spike should not depend on Universal Links or browser-extension-style routing.

Strict First-Spike Validation Order
The spike must validate this single narrow path, in order:

1. Request Screen Time / FamilyControls authorization
2. Select one specific app using FamilyActivityPicker
3. Persist the selected app token locally
4. Apply a shield to that selected app using ManagedSettingsStore
5. Attempt to open the blocked app
6. Show the custom shield
7. Tap the primary shield button: "Open Safe Place"
8. Shield Action Extension writes an App Group handoff marker
9. Shield Action Extension returns `ShieldActionResponse.openParentalControlsApp`
10. Main app opens
11. Main app reads the App Group marker
12. Main app immediately presents the Safe Place screen
13. Safe Place shows one video or placeholder module and four simple action buttons:
    - "The urge passed"
    - "Show me another video"
    - "I still need help"
    - "Close"
14. Treat `ShieldActionResponse.openParentalControlsApp` as the primary path to validate

Shield Action Behavior
The Shield Action extension should stay intentionally small.

Primary button behavior:
- Write a timestamped pendingSafePlaceLaunch marker into App Group storage.
- Set triggerKind to app (first spike validates one app only).
- Return `ShieldActionResponse.openParentalControlsApp`.

Secondary button behavior:
- Prefer a simple close/defer behavior for the spike.
- Do not implement bypass, unlock, delay, accountability, or escalation logic yet.

Unknowns to validate (first spike):
- Whether `openParentalControlsApp` opens the containing app reliably on a real supported iPhone.
- Whether the app can route immediately to Safe Place after launch.
- Whether the extension can persist handoff context before the app opens.

Deferred to later spikes (do not test in first spike):
- Category shields
- Domain/web shields
- Trigger-type distinctions beyond app
- Notification or manual fallback entry paths

App Group / Context Handoff
The handoff should be minimal and privacy-preserving.

Candidate handoff fields:
- pendingSafePlaceLaunch: Bool
- createdAt: Date
- triggerKind: app (fixed for first spike)
- sessionId: UUID

Do not store:
- full URLs
- page paths
- search queries
- exact browsing history
- sensitive user-entered text
- unnecessary app usage history

Main app launch behavior:
- Check App Group storage on foreground/open.
- If pendingSafePlaceLaunch is recent, route to Safe Place.
- Clear or mark the handoff as consumed.
- If no marker exists, open the normal home/setup screen.

Open validation question:
Define how long a handoff marker remains valid. A reasonable spike default is a short window, such as a few minutes, but this should be validated during testing.

Real-Device Validation Checklist
The spike must be tested on a real iPhone. Simulator results are not enough.

Device / OS Compatibility
- Confirm exact iOS version that supports `ShieldActionResponse.openParentalControlsApp`.
- Confirm the app refuses or avoids unsupported MVP test devices.
- Confirm behavior on the latest available supported OS version.

Authorization
- Screen Time authorization prompt appears.
- User can approve authorization.
- App can detect authorized/denied state.
- App behaves clearly if authorization is denied or revoked.

Target Selection (one app only)
- User can select one specific app.
- Selected app token can be persisted locally.
- Category and domain selection are not tested in the first spike.

Shield Application (one app only)
- Selected app can be shielded.
- Shield remains active after app relaunch.
- Shield behavior after device restart is documented.

Shield UI
- Custom shield title appears.
- Custom shield subtitle appears.
- Primary button appears.
- Secondary button behavior is understood.
- Copy feels supportive rather than punitive.

Shield Action / App Opening
- Primary button returns `openParentalControlsApp`.
- Main app opens reliably via `openParentalControlsApp`.
- Handoff marker is written before app opens.
- Main app reads handoff marker.
- Main app routes directly into Safe Place.
- Transition time feels acceptable during an urge moment.

Safe Place
- Safe Place appears without requiring navigation.
- One video or placeholder video module appears.
- Four action buttons appear.
- Buttons can record local-only session outcomes for the spike.
- "Show me another video" does not create an endless feed.

Failure Modes
- Authorization denied.
- Entitlement missing.
- Unsupported OS version.
- Shield applies but app does not open via `openParentalControlsApp`.
- App opens but no handoff marker is found.
- Handoff marker exists but is stale.

Success Criteria
The spike is successful if:
- A user can authorize Screen Time access on a supported real iPhone.
- A user can select one specific app.
- The app can shield that selected app.
- Attempting to open the blocked app shows a custom shield.
- Tapping "Open Safe Place" opens the main app using `ShieldActionResponse.openParentalControlsApp`.
- The main app detects the shield-originated launch through App Group handoff.
- The Safe Place appears immediately after launch.
- Safe Place shows one video or placeholder module and four action buttons.
- The flow feels simple enough for private testing.
- No backend, account system, or analytics is required.

Failure Criteria
The spike should be considered blocked or not viable as designed if:
- Required entitlements cannot be used for development testing.
- `openParentalControlsApp` is unavailable on target MVP devices.
- `openParentalControlsApp` does not reliably open the containing app.
- The Shield Action extension cannot write enough local context before app launch.
- The app cannot route to Safe Place after shield-originated launch.
- App Store/TestFlight entitlement constraints prevent closed beta planning.

If `openParentalControlsApp` fails, a follow-up spike may explore notification or manual fallback. That is not a first-spike failure mode to solve inline.

Spike Non-Goals
- App categories
- Domains / web filtering
- DeviceActivity Monitor extension
- DeviceActivity Report extension
- Scheduled interventions
- Notification-based fallback flow
- Production UI polish
- Full video library
- Backend
- User accounts
- Subscriptions
- Recommendation system
- Advanced analytics
- Crisis escalation workflow
- Social/accountability features
- Support for older iOS versions

Expected Output
An iOS developer should be able to produce a spike report with:
- target/device/OS details
- entitlement and provisioning notes
- screenshots or screen recordings
- one-app shield behavior
- `openParentalControlsApp` behavior
- App Group handoff behavior
- Safe Place routing result
- known limitations
- recommendation: proceed, proceed with changes, or stop

Build First
- Main app target
- Shield Configuration extension
- Shield Action extension
- Family Controls authorization
- FamilyActivityPicker (one specific app)
- one shielded app
- App Group handoff marker
- `openParentalControlsApp` shield action
- one Safe Place screen
- one local video or placeholder video module
- four Safe Place buttons

Do Not Build Yet
- app categories
- domains / web filtering
- DeviceActivity extensions
- scheduled interventions
- notification fallback flows
- backend
- accounts
- subscriptions
- advanced analytics
- recommendation engine
- large video library
- social/community features


## Main Feasibility Decision

The most important decision after this research is not whether video playback or SwiftUI screens are possible. Those are straightforward.

The real decision for the first spike is:

Does `ShieldActionResponse.openParentalControlsApp` reliably open the main app and route the user into Safe Place when shielding one specific selected app?

If yes, proceed to broader validation (categories, domains, scheduling).

If no, a follow-up spike may explore notification or manual fallback UX. The product may still be possible, but the Safe Place entry path must be redesigned around what `openParentalControlsApp` actually supports on real devices.
