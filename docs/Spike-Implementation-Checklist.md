# Spike Implementation Checklist

Minimal Xcode Spike — One App, Shield-to-Safe-Place Flow

Status: Planning artifact only. No Swift code in this document.
Scope: One specific selected app. Three targets. Family Controls + App Groups only.
Primary path dependency: `ShieldActionResponse.openParentalControlsApp` (Apple docs: iOS/iPadOS 26.5+).
Ready for: Stage 0 Git setup (after API availability is confirmed on dev Mac + test device).


## Stage 0 — Git + Planning Artifacts (Before Xcode)

**Actions**
- Initialize Git repository in project root.
- Add .gitignore for Xcode/macOS (DerivedData, xcuserdata, .DS_Store, etc.).
- Commit planning artifacts only:
  - docs/Feasibility-Research-Plan.md
  - docs/Spike-Implementation-Checklist.md
  - docs/AI-Change-Report-Protocol.md

Commit message suggestion:
  docs: add feasibility plan and spike implementation checklist

Do not commit:
- Xcode user-specific state
- Provisioning profiles with secrets
- .env or API keys (none needed for this spike)

Next step after Stage 0 commit:
- Run Stage 0.5 API availability check on your Mac and test iPhone before creating the Xcode project or proceeding to Milestone B/C.


## Stage 0.5 — API Availability Check (Before Milestone B / C)

This spike depends on `ShieldActionResponse.openParentalControlsApp` as the primary
Safe Place entry path. Apple documentation currently shows this API on iOS/iPadOS
26.5+. Do not assume iOS 17.0 is sufficient.

Run this check after Stage 0 (Git + planning docs) and before entitlements work,
device provisioning for feature code, or authorization implementation.

On your Mac (Xcode SDK)
- [ ] Open the installed Xcode version you will use for the spike.
- [ ] Confirm ManagedSettings (or ManagedSettingsUI) exposes `ShieldActionResponse.openParentalControlsApp` in the SDK:
      - Quick check: Xcode > Open Developer Documentation, search `openParentalControlsApp`
      - Or create a throwaway file importing ManagedSettings and verify autocomplete / symbol availability
- [ ] Note the Xcode version and SDK version in README or spike notes.
- [ ] Do not set a final deployment target until this symbol is confirmed in your SDK.

On your test iPhone / iPad
- [ ] Confirm device OS version (Settings > General > About).
- [ ] Device must run an iOS/iPadOS version that supports `openParentalControlsApp` (26.5+ per current Apple docs).
- [ ] If the device OS is too old, stop the spike and document: primary path cannot be tested on this setup.

Go / no-go decision
- GO: SDK exposes `openParentalControlsApp` AND test device is on a supported OS version.
      Proceed to Milestone A (Xcode project) and Milestone B (entitlements/signing).
- NO-GO: API missing from SDK OR test device below required OS.
      Stop the spike. Document Xcode version, SDK, device model, and OS version.
      Do not implement authorization, shielding, or Safe Place routing until a supported setup exists.
      Do not lower scope to notification/manual fallback in this spike.

Record in spike notes (template)
- Xcode version:
- iOS SDK version:
- `openParentalControlsApp` found in SDK: yes / no
- Test device model:
- Test device OS:
- OS meets 26.5+ requirement: yes / no
- Decision: proceed / stop


## 1. Required Xcode Project Setup
Project type
- iOS App (SwiftUI)
- Interface: SwiftUI
- Language: Swift

Deployment target (do not finalize until Stage 0.5 passes)
- Do NOT assume iOS 17.0 is sufficient for this spike.
- The primary spike path requires `ShieldActionResponse.openParentalControlsApp`.
- Apple documentation currently shows `openParentalControlsApp` on iOS/iPadOS 26.5+.
- Set the Xcode project deployment target only after confirming API availability in your installed SDK (Stage 0.5).
- Use the SDK that exposes `openParentalControlsApp`; match or exceed the documented minimum OS for that API.
- Spike supports only OS versions where `openParentalControlsApp` can be compiled and run on a real device.

Test device requirement
- Physical iPhone or iPad must run an iOS/iPadOS version that supports `openParentalControlsApp`.
- Simulator is not valid for shield or `openParentalControlsApp` validation.

Project name (placeholder)
- SafePlaceSpike

Organization / Team
- Use personal or team Apple Developer account with Family Controls development capability enabled.

Signing
- Automatic signing for all three targets.
- Same development team on main app and both extensions.

Frameworks (link only what is needed)
- Main app: FamilyControls, ManagedSettings, SwiftUI
- Shield Configuration extension: ManagedSettingsUI
- Shield Action extension: ManagedSettings

Extension creation (in Xcode)
- File > New > Target > Shield Configuration Extension
- File > New > Target > Shield Action Extension
- Do NOT add Device Activity Monitor or Device Activity Report targets.

Info.plist / extension configuration
- Ensure each extension has correct NSExtension configuration for its type.
- Main app must declare Family Controls usage purpose clearly in onboarding copy (no special Info.plist key required beyond entitlements, but document why access is requested for App Store review later).

Build settings to verify
- All targets: same Swift language version.
- Extensions: APPLICATION_EXTENSION_API_ONLY = YES.
- Main app embeds both extensions in "Embed Foundation Extensions" build phase.

Provisioning
- Enable Family Controls capability on Apple Developer portal for each bundle ID before device testing.
- Regenerate provisioning profiles after adding capabilities.


## 2. Required Targets And Responsibilities
Target                          | Product Type              | What It Does
--------------------------------|---------------------------|----------------------------------------------
SafePlaceSpike                  | iOS Application           | Auth, app picker, shield apply/clear, handoff read, Safe Place UI, spike debug status
SafePlaceSpikeShieldConfig      | Shield Configuration Ext  | Supplies custom shield title, subtitle, button labels
SafePlaceSpikeShieldAction      | Shield Action Extension   | Handles shield button taps, writes App Group marker, returns `openParentalControlsApp`


Out of scope (do not create)
- Device Activity Monitor extension
- Device Activity Report extension
- App Clip, Watch, Widget, Notification Service extensions


## 3. Required Capabilities / Entitlements Per Target
Placeholder team prefix: com.yourcompany
Replace with your real reverse-DNS prefix before creating the Xcode project.

Target: SafePlaceSpike (main app)
- Family Controls (com.apple.developer.family-controls)
- App Groups (group.com.yourcompany.safeplace.spike)
- Push Notifications: OFF
- Associated Domains: OFF
- Background Modes: OFF (not needed for spike)

Target: SafePlaceSpikeShieldConfig
- Family Controls (com.apple.developer.family-controls)
- App Groups: OFF for spike (config extension does not need shared storage)
- Push Notifications: OFF

Target: SafePlaceSpikeShieldAction
- Family Controls (com.apple.developer.family-controls)
- App Groups (group.com.yourcompany.safeplace.spike)
- Push Notifications: OFF

Apple Developer portal checklist
- [ ] Family Controls enabled for main app bundle ID
- [ ] Family Controls enabled for Shield Configuration bundle ID
- [ ] Family Controls enabled for Shield Action bundle ID
- [ ] App Group created and assigned to main app + Shield Action only
- [ ] Provisioning profiles refreshed for all three targets


## 4. App Group Identifier (Placeholder)
App Group ID
- group.com.yourcompany.safeplace.spike

Shared storage keys (UserDefaults suite or file in container)
- pendingSafePlaceLaunch    Bool
- createdAt               Date (ISO8601 or timeIntervalSince1970)
- triggerKind             String, fixed value "app" for spike
- sessionId               String (UUID)

Handoff validity (spike default)
- 5 minutes from createdAt; mark consumed on read

Do not store
- URLs, domains, app names, browsing history, or usage telemetry


## 5. Bundle Id Assumptions (Placeholders)
Main app
- com.yourcompany.safeplace.spike

Shield Configuration extension
- com.yourcompany.safeplace.spike.ShieldConfig

Shield Action extension
- com.yourcompany.safeplace.spike.ShieldAction

URL scheme (optional, spike-only debug)
- safeplacespike://  (only if needed for local debug; not part of primary validation path)

Rule
- Every target bundle ID that uses Family Controls must be registered and entitled separately.


## 6. Minimal Folder Structure
SafePlaceSpike/
├── docs/
│   ├── Feasibility-Research-Plan.md
│   ├── Spike-Implementation-Checklist.md
│   └── AI-Change-Report-Protocol.md
├── .gitignore
├── README.md                                (optional: spike purpose + device test notes)
│
└── Heal/                                    (Xcode project root; actual name: Heal)
    ├── SafePlaceSpike.xcodeproj
    │
    ├── SafePlaceSpike/                      (main app target)
    │   ├── SafePlaceSpikeApp.swift
    │   ├── ContentView.swift
    │   ├── Views/
    │   │   ├── SetupView.swift
    │   │   ├── AppSelectionView.swift
    │   │   ├── ShieldStatusView.swift
    │   │   └── SafePlaceView.swift
    │   ├── Services/
    │   │   ├── AuthorizationService.swift
    │   │   ├── ShieldService.swift
    │   │   ├── SelectionPersistence.swift
    │   │   └── HandoffStore.swift
    │   ├── Models/
    │   │   ├── SpikeAppState.swift
    │   │   └── HandoffPayload.swift
    │   ├── Resources/
    │   │   ├── Assets.xcassets
    │   │   └── placeholder-video.mp4    (optional local file; placeholder UI acceptable)
    │   └── SafePlaceSpike.entitlements
    │
    ├── SafePlaceSpikeShieldConfig/        (Shield Configuration extension)
    │   ├── ShieldConfigurationExtension.swift
    │   └── SafePlaceSpikeShieldConfig.entitlements
    │
    └── SafePlaceSpikeShieldAction/        (Shield Action extension)
        ├── ShieldActionExtension.swift
        ├── HandoffWriter.swift            (thin helper; can be inline in extension for spike)
        └── SafePlaceSpikeShieldAction.entitlements


File count target: ~15 Swift files across 3 targets. Keep helpers minimal.


## 7. Minimal Swift Files Needed
Main app (11 files)
- SafePlaceSpikeApp.swift
- ContentView.swift
- SetupView.swift
- AppSelectionView.swift
- ShieldStatusView.swift
- SafePlaceView.swift
- AuthorizationService.swift
- ShieldService.swift
- SelectionPersistence.swift
- HandoffStore.swift
- SpikeAppState.swift
- HandoffPayload.swift

Shield Configuration extension (1 file)
- ShieldConfigurationExtension.swift

Shield Action extension (1–2 files)
- ShieldActionExtension.swift
- HandoffWriter.swift (optional thin wrapper)


## 8. File Responsibilities
MAIN APP

SafePlaceSpikeApp.swift
- App entry point.
- Create shared SpikeAppState.
- On launch and scene phase .active: call HandoffStore to check for pending Safe Place route.

ContentView.swift
- Root router: Setup vs App Selection vs Shield Status vs Safe Place.
- Driven by SpikeAppState (authorization, selection, handoff, current screen).

SetupView.swift
- Explain why Screen Time access is needed (spike copy only).
- Button to request FamilyControls authorization via AuthorizationService.
- Show authorized / denied / not determined states.

AppSelectionView.swift
- Present FamilyActivityPicker bound to one ApplicationToken selection.
- Enforce one app only (ignore or clear category/domain selections if picker returns them).
- Save selection via SelectionPersistence.
- Button to apply shield via ShieldService.

ShieldStatusView.swift
- Show spike debug state: authorization status, whether one app is selected, whether shield is active.
- Button to clear shield (for retesting).
- Instruction text: "Now try opening the blocked app."

SafePlaceView.swift
- Spike-only placeholder for Safe Place entry (not final product architecture).
- Milestone I: minimal title, supportive message, optional shield-handoff debug text, "Back to app".
- May later evolve into home feed, Reels-style experience, or shared content with different entry context.
- Milestone J adds: placeholder video module and four outcome buttons (not in Milestone I).

AuthorizationService.swift
- Wrap AuthorizationCenter.shared.
- Request authorization for .individual.
- Expose authorization status to SpikeAppState.

ShieldService.swift
- Own one ManagedSettingsStore instance for spike.
- Apply shield to stored ApplicationToken only.
- Clear shield settings for retesting.
- Do not shield categories or web domains.

SelectionPersistence.swift
- Persist encoded FamilyControls selection (ApplicationToken) to UserDefaults or file in app container.
- Load on app launch.
- Spike: store one app token only.

HandoffStore.swift
- Read/write HandoffPayload via App Group UserDefaults suite.
- isPendingAndValid(within: TimeInterval) -> Bool
- consumeHandoff() clears pendingSafePlaceLaunch after routing

SpikeAppState.swift
- Observable object holding:
  - authorizationStatus
  - hasSelectedApp
  - isShieldActive
  - pendingSafePlaceEntry (temporary spike routing flag; not final nav)
  - launchContext (openedFromShieldHandoff, sessionId, createdAt)
  - handoff debug fields (lastHandoffSessionId, etc.)

HandoffPayload.swift
- Codable struct: pendingSafePlaceLaunch, createdAt, triggerKind, sessionId

SHIELD CONFIGURATION EXTENSION

ShieldConfigurationExtension.swift
- Subclass / implement ShieldConfigurationDataSource (per Apple template).
- Return configuration for .application (and default fallback for other cases if required by API).
- Title: supportive, e.g. "Pause for a moment"
- Subtitle: e.g. "You chose to protect yourself from this app."
- Primary button label: "Open Safe Place"
- Secondary button label: "Close"

SHIELD ACTION EXTENSION

ShieldActionExtension.swift
- Implement ShieldActionDelegate (per Apple template).
- On primary button: write handoff via HandoffWriter, return .`openParentalControlsApp` (ShieldActionResponse).
- On secondary button: return .close (or defer — document observed behavior).

HandoffWriter.swift (optional)
- Write HandoffPayload fields to App Group UserDefaults.
- Set triggerKind = "app" always for spike.


## 9. Exact Implementation Order
Milestone A — Repository and empty Xcode shell
- [ ] Stage 0.5 API availability check passed (GO decision recorded)
- [ ] Git init + .gitignore
- [ ] Commit plan + checklist (Stage 0)
- [ ] Create Xcode project SafePlaceSpike (SwiftUI)
- [ ] Use Xcode SDK that exposes `openParentalControlsApp`; set deployment target per Stage 0.5 (not iOS 17.0 by default)
- [ ] Set bundle IDs (placeholders)
- [ ] Add Shield Configuration + Shield Action extension targets
- [ ] Verify project builds for simulator (extensions may not run in sim; build success only)

Milestone B — Entitlements and signing
- [ ] Prerequisite: Stage 0.5 GO + Milestone A complete
- [ ] Create App Group in Developer portal
- [ ] Enable Family Controls on all three bundle IDs
- [ ] Add entitlements files per target (Section 3)
- [ ] Assign same team; fix signing errors
- [ ] Build to real iPhone (blank app) to confirm provisioning works

Milestone C — Authorization (main app only)
- [ ] Prerequisite: Stage 0.5 GO (`openParentalControlsApp` available on SDK + test device OS)
- [ ] AuthorizationService.swift
- [ ] SpikeAppState.swift
- [ ] SetupView.swift + ContentView.swift wiring
- [ ] Device test: authorization prompt and approve/deny handling

Milestone D — One-app selection + persistence
- [ ] SelectionPersistence.swift
- [ ] HandoffPayload.swift (model only; no App Group yet)
- [ ] AppSelectionView.swift with FamilyActivityPicker (apps only)
- [ ] Device test: select one app, kill app, relaunch, selection still present

Milestone E — Shield application
- [ ] ShieldService.swift
- [ ] ShieldStatusView.swift
- [ ] Device test: apply shield, open blocked app, system shield appears (may be default until Milestone F)

Milestone F — Shield Configuration extension
- [ ] ShieldConfigurationExtension.swift with custom copy
- [ ] Device test: blocked app shows custom title, subtitle, buttons

Milestone G — App Group handoff (write path)
- [ ] HandoffWriter in Shield Action target (or inline)
- [ ] HandoffStore.swift in main app (read path)
- [ ] Device test: temporarily log/handoff write from extension if needed (debug only)

Milestone H — Shield Action + `openParentalControlsApp`
- [ ] ShieldActionExtension.swift primary -> write handoff -> `openParentalControlsApp`
- [ ] Secondary -> close
- [ ] Device test: tap "Open Safe Place", main app opens

Milestone I — Safe Place handoff routing (technical spike only)
Product note: This milestone proves handoff → entry only. It does NOT decide final
product navigation. Safe Place may later be the main home experience (e.g. Reels/feed),
a dedicated intervention screen, or the same content surface with a different entry
context. Do not add tabs, final navigation architecture, or assume Safe Place is a
permanent separate page.

- [ ] HealApp.swift: scene phase / launch handoff check via `evaluatePendingSafePlaceEntry()`
- [ ] ContentView routes to minimal `SafePlaceView` placeholder when valid pending marker exists
- [ ] SpikeAppState: flexible entry state (`pendingSafePlaceEntry`, `launchContext`) — not final nav
- [ ] Route only when `readMarker()` returns valid marker: pending, not stale, triggerKind == "app", sessionId present
- [ ] Consume marker in `SafePlaceView.onAppear` (after placeholder is presented), not before
- [ ] Normal relaunch after consume does not re-trigger Safe Place entry
- [ ] Device test: app opens directly into Safe Place placeholder without manual navigation

Milestone J — Safe Place placeholder UI (content module)
- [ ] Expand SafePlaceView with placeholder video module (if not done in I)
- [ ] Four outcome buttons with local-only logging (print or in-memory)
- [ ] Device test: full 14-step validation order end-to-end

Milestone K — Spike hardening (still minimal)
- [ ] Clear shield button for retest loop
- [ ] Stale handoff handling (>5 min ignored)
- [ ] Denied authorization UI state
- [ ] Document reboot + force-quit behavior in README or spike report template
- [ ] Final device test pass + screenshots/screen recording


## 10. Manual Real-iPhone Test Checklist (After Each Milestone)
After Stage 0.5 (API availability) — before any Xcode feature work
- [ ] `openParentalControlsApp` confirmed in installed Xcode SDK
- [ ] Test device OS version recorded
- [ ] Test device meets iOS/iPadOS 26.5+ (per current Apple docs for this API)
- [ ] GO/NO-GO decision documented
- [ ] If NO-GO: spike stopped; no further milestones attempted

After Milestone B (signing)
- [ ] App installs on physical iPhone
- [ ] No immediate crash on launch
- [ ] Xcode shows correct team and bundle ID

After Milestone C (authorization)
- [ ] Tap "Enable Screen Time Access" (or equivalent)
- [ ] System authorization sheet appears
- [ ] Approve: UI shows authorized state
- [ ] Deny (optional retest on second install): UI shows clear denied state

After Milestone D (selection)
- [ ] FamilyActivityPicker opens
- [ ] Exactly one app can be selected for spike test
- [ ] Selection survives app restart
- [ ] No category/domain selection required or stored

After Milestone E (shield)
- [ ] "Apply Shield" activates restriction
- [ ] Opening blocked app is interrupted (shield or blank block)
- [ ] Shield survives main app relaunch
- [ ] "Clear Shield" removes block

After Milestone F (shield UI)
- [ ] Custom title visible on shield
- [ ] Custom subtitle visible
- [ ] "Open Safe Place" primary button visible
- [ ] "Close" secondary button visible

After Milestone G (handoff write — if tested in isolation)
- [ ] After primary tap, App Group contains pendingSafePlaceLaunch = true
- [ ] createdAt and sessionId present
- [ ] triggerKind = "app"

After Milestone H (`openParentalControlsApp`)
- [ ] Primary shield button opens main app (not Settings, not wrong app)
- [ ] Transition time noted (acceptable / not acceptable)
- [ ] Secondary button closes/deferrs without opening app

After Milestone I (handoff routing spike)
- [ ] Main app opens directly to Safe Place placeholder (no extra taps through app selection)
- [ ] Handoff consumed after SafePlaceView appears (second launch does not auto-open Safe Place)
- [ ] Stale handoff (>5 min) does not open Safe Place
- [ ] Implementation does not lock Safe Place as a permanent separate final page (flexible naming/context only)

After Milestone J (full flow)
Complete strict 14-step validation:
- [ ] 1. Authorization granted
- [ ] 2. One app selected
- [ ] 3. Token persisted
- [ ] 4. Shield applied
- [ ] 5. Blocked app launch attempted
- [ ] 6. Custom shield shown
- [ ] 7. "Open Safe Place" tapped
- [ ] 8. Handoff marker written
- [ ] 9. `openParentalControlsApp` returned
- [ ] 10. Main app opens
- [ ] 11. Handoff marker read
- [ ] 12. Safe Place presented immediately
- [ ] 13. Video/placeholder + four buttons visible
- [ ] 14. Primary path validated (document result)

After Milestone K (hardening)
- [ ] Reboot device: shield still active (document behavior)
- [ ] Force-quit main app, trigger shield again: flow still works
- [ ] Revoke Screen Time permission in Settings: app handles gracefully

Record for spike report
- iPhone model, iOS version, Xcode version, date, pass/fail per step, screenshots


## 11. Common Setup Mistakes To Avoid
Entitlements
- Enabling Family Controls only on main app but not on extension targets.
- Mismatched App Group identifier string between portal, entitlements, and code.
- Forgetting to regenerate provisioning profiles after adding capabilities.

Bundle IDs
- Extension bundle ID not nested under main app ID pattern.
- Using same bundle ID for multiple targets.

Targets
- Adding Device Activity extensions "just in case."
- Embedding extensions incorrectly (missing Embed Foundation Extensions).

API usage
- Using FamilyControlsMember.child instead of .individual for self-control spike.
- Shielding categories or web domains during first spike.
- Expecting human-readable app names from ApplicationToken.

Shield extensions
- Putting heavy logic or async network calls in Shield Action extension.
- Not returning `openParentalControlsApp` on primary button.
- Writing handoff to standard UserDefaults instead of App Group suite.

Main app
- Checking handoff only on cold launch but not on scenePhase .active (misses return from shield).
- Never consuming handoff (Safe Place opens on every foreground).
- Routing to Safe Place before handoff is written (race — validate on device).

Testing
- Skipping Stage 0.5 and assuming iOS 17.0 is enough for `openParentalControlsApp`.
- Creating the Xcode project before confirming `openParentalControlsApp` exists in the installed SDK.
- Using a test device below the OS version required for `openParentalControlsApp` (currently 26.5+ per Apple docs).
- Relying on Simulator for shield behavior (invalid for this spike).
- Testing on unsupported iOS version for `openParentalControlsApp`.
- Not using a real blocked app installed on device (picker must select installed app).

Git / project hygiene
- Committing xcuserdata or DerivedData.
- Committing personal provisioning profiles.


## 12. What to Commit to Git After Each Stage
Stage 0 — Planning
- docs/Feasibility-Research-Plan.md
- docs/Spike-Implementation-Checklist.md
- docs/AI-Change-Report-Protocol.md
- .gitignore

Commit: docs: add feasibility plan and spike implementation checklist

---

Stage 0.5 — API availability (no code commit required if NO-GO)
- Record GO/NO-GO in README.md or docs/spike-setup-notes.md
- If GO: note Xcode version, SDK version, test device model, OS version
- If NO-GO: document stop reason; do not proceed to Milestone A

Optional commit: docs: record `openParentalControlsApp` availability check (GO/NO-GO)

---

Stage A — Xcode shell
- SafePlaceSpike.xcodeproj (and/or workspace if created)
- Empty SwiftUI app template files
- Extension target folders with Apple template stubs
- Assets.xcassets (default)
- .gitignore updates if needed

Do not commit: xcuserdata/, *.xcuserstate

Commit: chore: create SafePlaceSpike Xcode project with shield extensions

---

Stage B — Entitlements
- SafePlaceSpike.entitlements
- SafePlaceSpikeShieldConfig.entitlements
- SafePlaceSpikeShieldAction.entitlements
- Project file changes for capabilities

Commit: chore: add Family Controls and App Group entitlements

---

Stage C — Authorization
- AuthorizationService.swift
- SpikeAppState.swift
- SetupView.swift
- ContentView.swift (partial)
- SafePlaceSpikeApp.swift (partial)

Commit: feat: add Family Controls authorization flow

---

Stage D — App selection
- AppSelectionView.swift
- SelectionPersistence.swift
- HandoffPayload.swift
- ContentView routing updates

Commit: feat: add single-app FamilyActivityPicker and persistence

---

Stage E — Shield apply
- ShieldService.swift
- ShieldStatusView.swift

Commit: feat: apply ManagedSettings shield to selected app

---

Stage F — Shield Configuration
- ShieldConfigurationExtension.swift (custom copy)

Commit: feat: customize shield configuration UI

---

Stage G + H — Shield Action + handoff
- ShieldActionExtension.swift
- HandoffWriter.swift (if separate)
- HandoffStore.swift

Commit: feat: shield action handoff and `openParentalControlsApp`

---

Stage I + J — Safe Place
- SafePlaceView.swift
- SafePlaceSpikeApp.swift (handoff routing)
- ContentView.swift (Safe Place route)
- placeholder-video.mp4 OR documented placeholder-only UI

Commit: feat: route shield launch into Safe Place screen

---

Stage K — Spike hardening + docs
- README.md with device test results template
- Any small bugfix commits
- docs/spike-report.md (optional: pass/fail, iOS version, screenshots links)

Commit: docs: add spike test notes and retest helpers

---

End state repository should contain
- Planning docs at repo root
- Minimal spike app proving one-app shield -> `openParentalControlsApp` -> Safe Place
- No backend, no analytics SDKs, no notification code, no DeviceActivity code


## Spike Success Reminder (Do Not Expand Scope)
Pass = all true on real iPhone
- One app selected and shielded
- Custom shield appears
- `openParentalControlsApp` opens main app
- App Group handoff detected
- Safe Place immediate with video/placeholder + 4 buttons

If `openParentalControlsApp` fails on a supported setup: stop, document, plan follow-up spike only for fallback UX.
If API or OS is unavailable at Stage 0.5: stop before Xcode setup; do not substitute iOS 17.0 or notification fallback in this spike.
Do not add categories, domains, DeviceActivity, notifications, or backend to "fix" the first spike.