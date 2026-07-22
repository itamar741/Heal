# Heal MVP Product-Validation Plan

Status: canonical implementation plan; planning only
Repository snapshot: `7522b129bc0bd90ad702456de22b5c5631779ae4`
Primary experiment: Safari intervention path
Audience: product, research, engineering, privacy/legal reviewers, and future implementation agents

This document replaces chat history as the source for planning Heal's first product-validation MVP. It records confirmed product decisions, repository facts, recommended architecture, unresolved decisions, milestone boundaries, and verification requirements. It does not approve legal wording, create a backend, or authorize implementation beyond an individually reviewed milestone.

Normative labels used throughout:

- **Confirmed**: a product or experiment decision already made for this MVP.
- **Repository fact**: behavior verified at the repository snapshot above.
- **Recommendation**: the preferred implementation direction, subject to the named milestone's review.
- **Open decision**: a choice that must be resolved explicitly; an implementation agent must not invent an answer. All open decisions are consolidated in section 27.

Global rules that apply to every milestone and are not restated per section:

- Follow `.cursor/rules/mandatory-prompt-verification.mdc`, `docs/AI-Coding-Guardrails.md`, and `docs/AI-Change-Report-Protocol.md`, including the Planned Change step and waiting for reviewer confirmation before edits.
- Preserve the Xcode shared-schemes stash (`local Xcode shared schemes before M7`) unless separately authorized.
- Sensitive study data (urge values, behavior, protection state, free text) never appears in logs, crash metadata, or diagnostic payloads.
- No milestone chains into the next; each stops before commit.

---

## 1. Product hypothesis and experiment question

### 1.1 Hypothesis

**Confirmed**

> A timely intervention during a moment of weakness, followed by a fast transition into Safe Place content, helps the user calm down and reduce the current urge.

The first MVP evaluates the intervention, not the strength of the blocking mechanism. It is not intended to prove tamper resistance, long-term retention, social effects, or commercial readiness.

### 1.2 Primary experiment question

Among approved adult study participants whose Safe Place session is initiated by a `safari_block_page` entry (the primary study cohort; section 7.3), does the participant's last answered numerical urge measurement within that session tend to be lower than the first answered numerical urge measurement in that same session?

The experiment also asks:

- How often is there enough within-session data to calculate urge change in the primary Safari cohort?
- How does urge change relate to active session, Breathe, feed, and playback time, and to content actually viewed?
- How often do participants return rapidly, including multiple sessions in one intervention episode?
- How do outcomes and behavior differ across cohorts: primary (`safari_block_page`-initiated), secondary (`manual_in_app`-initiated), and non-primary (`app_shield`-initiated or otherwise excluded)?
- Which prompts are shown, answered, or skipped, and where does measurement friction appear?

### 1.3 Study path

**Confirmed**

- Safari is the study path for the first external experiment: the primary study cohort and primary efficacy analysis include sessions whose initiating entry source is `safari_block_page` (section 7.3).
- Manual `Enter Safe Place` remains a product feature; `manual_in_app`-initiated sessions are recorded with all approved measurements and analyzed as a separate secondary cohort.
- Existing app-shield functionality may remain operational with typed `app_shield` provenance, but `app_shield`-initiated sessions remain outside the primary first-study cohort and analyses unless separately approved later.
- Safe Place remains a vertical video feed.
- The first study content library uses a mixture of YouTube-hosted videos and Heal-hosted media (section 13.5); implementations remain split across milestones, but both are required for the currently planned external-study build.
- External distribution is private TestFlight external testing with individual invitations.
- Backend access is separately restricted to approved participant email addresses.
- The study is for participants aged 18 or older.

---

## 2. Success criteria and limitations

### 2.1 Product-validation success

The MVP is successful as an experiment platform when it can:

- route an explicit Safari block-page CTA into Safe Place without treating an ordinary icon launch as an entry;
- run the Breathe, feed, scheduled-prompt, and explicit-exit flows with the exact timing and interaction semantics in sections 8–12;
- preserve raw entries, sessions, episodes, prompts, measurements, content views, and playback segments;
- calculate the primary metric without relying on irreversible aggregates;
- continue the intervention and durably record data during temporary network loss, then upload idempotently;
- keep participant identity, consent, and deletion behavior separate from view code;
- produce data that can be reconciled in the selected backend's tables and CSV exports before any custom dashboard is required (Supabase is the current candidate);
- pass the acceptance and physical-device matrix in section 25.

### 2.2 Research success threshold

**Open decision** (section 27.1)

No numerical efficacy threshold, minimum eligible-session count, target effect size, or required confidence interval has been approved. Engineering must not encode an invented threshold. The MVP must report eligible and ineligible session counts, the distribution of `urge_improvement`, missing and skipped measurement rates, participant and session denominators, and data-quality exclusions with reasons.

### 2.3 Limitations

- This is an observational product-validation MVP, not proof of causality by itself.
- Self-reported urge is subjective, and prompting can influence behavior and response rates.
- Participants are individually recruited and not representative of all potential users.
- Safari block-page CTA taps are observable in the first measurement milestone; every blocked-page appearance is not (section 21).
- iOS does not guarantee precise app-termination detection.
- Heal cannot know the exact moment a participant disables protection outside the app.
- YouTube availability, embed behavior, and measurement depend on provider behavior and policy.
- TestFlight, Family Controls distribution entitlements, and Beta App Review can constrain distribution.
- Heal is not a substitute for professional treatment or emergency help.

---

## 3. Current repository map and gap analysis

### 3.1 Root navigation and lifecycle

**Repository facts**

- `Heal/HealApp.swift`: `HealApp` creates one app-scoped `SpikeAppState`, `OnboardingProgress`, and `ProtectionRepairSession`; `.task` and active `scenePhase` refresh state and evaluate shield handoff; `.onOpenURL` delegates to `SpikeAppState.handleIncomingURL(_:)`.
- `Heal/ContentView.swift`: `ContentView.body` owns root priority — initial refresh, `pendingSafePlaceEntry`, incomplete onboarding, protection repair, then `PostOnboardingRootView` (`AppSelectionView` when Screen Time authorization is approved, otherwise `SetupView`).
- `Heal/SpikeAppState.swift`: combines authorization orchestration, one-app selection, shield synchronization, handoff diagnostics, and Safe Place route state. `pendingSafePlaceEntry` is a Boolean; `LaunchContext` preserves only limited shield-handoff context.

**Gap**: no normal Heal product home; a Boolean pending route cannot preserve multiple explicit entries during one session and is not a source-provenance model.

### 3.2 Safe Place presentation and dismissal

**Repository facts**

- `Heal/SafePlaceView.swift`: full-screen, private phases `.breathing` and `.video`; `onAppear` calls `SpikeAppState.consumeHandoffMarkerAfterPresentation()`; `Exit Safe Place` immediately calls `dismissSafePlaceEntry()`, after which root routing reveals onboarding, repair, or the spike post-onboarding root.

**Gap**: no session owner, active-time owner, urge prompts, exit feedback, inactivity timeout, exit state machine, or durable recovery checkpoint.

### 3.3 Existing Breathe screen

**Repository fact**: there is no separate `BreatheView`; `SafePlaceView.breathingScreen` shows static copy (`Breathe in slowly. Hold for a moment. Breathe out.`) and `Continue` moves directly to `.video`.

**Required refactor**: the phase must be owned by the session state machine, measured separately, and include the optional `0–10` urge question above Continue (section 10).

### 3.4 Current video/feed implementation and content ownership

**Repository facts**

- `Heal/SafePlaceVideoCatalog.swift`: `videoIDs` is a finite ordered list of 14 hard-coded YouTube IDs.
- `Heal/SafePlaceView.swift`: `videoPager` is a vertical paging `ScrollView`/`LazyVStack`; only the active page mounts its player.
- `Heal/YouTubeEmbedWebView.swift`: wraps one `WKWebView` and official YouTube iframe; configures inline playback, app identity, retry, navigation restrictions, and teardown; requests `loop=1` with the current video ID as playlist, so each active item repeats indefinitely; intentionally no IFrame API or JavaScript bridge; `WKNavigationDelegate.didFinish` proves only wrapper-document loading, not playback readiness, actual seconds played, completion, or player errors.

**Reuse**: pager interaction, one-active-player memory boundary, curated static content for a controlled study.

**Required refactor**: coordinated navigation for prompt insertion; stable internal content IDs, source type, and catalog version; player adapters that emit actual playback facts; per-view load state instead of one shared `embedLoadState`.

### 3.5 Safari block-page callback routing

**Repository facts**

- `HealSafariExtension/Resources/blocked.html` links to `heal://safe-place`; its body still contains spike-era `example.com` wording that must be reviewed before participant-facing distribution.
- `HealSafariExtension/Resources/blocked-test.html` links to `heal://safe-place?source=safariProtectionTest`.
- `Heal/Info.plist` registers the `heal` scheme; `HealApp` forwards URLs; `SpikeAppState.handleIncomingURL(_:)` accepts the explicit route, rejects malformed extra path segments, optionally marks a valid functional test passed via `SafariProtectionTestStore.markPassedIfPendingValid()`, then sets `pendingSafePlaceEntry`.
- `HealSafariExtension/SafariWebExtensionHandler.swift` is an echo stub; routing is HTML-link-only.

**Required refactor**: the production callback must create a typed research entry request with source `safari_block_page`. The functional-test callback must present Safe Place in an explicit non-study `functionalVerification` presentation context and must not create research entities (section 7.3).

### 3.6 App-shield Safe Place routing

**Repository facts**

- `HealShieldConfig/ShieldConfigurationExtension.swift` presents the custom shield (`Open Safe Place`).
- `HealShieldAction/ShieldActionExtension.swift` writes a marker via `HealShieldAction/HandoffWriter.swift` (App Group keys: pending flag, creation time, trigger kind, UUID) and returns `.openParentalControlsApp`.
- `Heal/HandoffStore.swift` reads/consumes recent markers from `group.com.itamar.Heal`; validity five minutes. `SpikeAppState.evaluatePendingSafePlaceEntry()` accepts `app` and `webDomain` trigger kinds.

**Reuse**: the extension/main-app ownership boundary remains.

**Known transport limitation (conditional architecture note)**: the single mutable App Group marker can overwrite an earlier unconsumed request, and consume-on-view-appearance is not a durable acknowledgement. Because app-shield sessions are excluded from the primary first-study cohort, a durable multi-record handoff inbox/acknowledgement redesign is **not** a dependency of the Safari-first MVP. It is a separate later milestone (section 24, "Later — app-shield durable handoff inbox"), required only if app-shield entries are approved for study analysis or the overwrite risk becomes operationally material.

### 3.7 Onboarding and completion persistence

**Repository facts**

- `Heal/OnboardingProgress.swift` is the single writer of app-local onboarding flags in `UserDefaults.standard` (introduction acknowledgement, two manual Safari confirmations, the System Website Filtering Enable/Skip decision, explicit completion).
- `Heal/OnboardingFlowView.swift` derives the visible step; no persisted writable step index.
- `SafariProtectionTestStore` separately owns test pending/pass/expiry timestamps.

**Required extension**: participant authentication, installation registration, versioned consent, and account state need separate owners; do not add them to `OnboardingProgress`.

### 3.8 Repair and protection refresh

**Repository facts**

- `ProtectionRepairEvaluator.issues(...)` in `Heal/ProtectionRepairSession.swift` derives Screen Time, Safari extension, and expected System Website Filtering issues; `ProtectionRepairSession` owns only process-scoped deferral.
- `ProtectionRepairHost`/`ProtectionRepairView` refresh live state on appear/foreground; `SpikeAppState.refreshSystemState()` refreshes on launch/foreground; `OnboardingFlowView`, `SetupView`, and `AppSelectionView` have scope-specific refresh paths.

**Reuse**: the services and evaluator are suitable foundations for home protection status and Repair. Whether Repair remains a mandatory post-onboarding root gate or becomes a home-reachable destination is an open routing decision (sections 6.2, 27.1).

### 3.9 Existing protection services

**Repository facts**

- `AuthorizationService` wraps live `AuthorizationCenter` status and individual authorization.
- `ShieldService` owns the default `ManagedSettingsStore` app shield; `WebsiteShieldService` owns the DEBUG-only `websiteFeasibility` named store; `SystemWebFilteringService` owns the `systemWebFiltering` named store and observable live filter state. These stores are intentionally separate and must not be merged.
- `SafariExtensionService` queries extension enablement and opens settings; `SafariExtensionEnablementModel` owns ephemeral UI state, refresh cancellation, and settings rate-limit presentation.
- Authorization-predicate mismatch: `SpikeAppState.isAuthorizationApproved` accepts `.approved` and `.approvedWithDataAccess`, while `SystemWebFilteringService.requireAuthorization()` accepts only `.approved`. One reviewed predicate per capability must be defined before reuse (section 27.3).

### 3.10 Existing local persistence

**Repository facts**

- `OnboardingProgress` and `SafariProtectionTestStore`: app-local `UserDefaults`. `SelectionPersistence`: atomic JSON in Application Support. `HandoffStore`/`HandoffWriter`: App Group `UserDefaults`. Managed Settings services: system-owned state.
- `ProtectionRepairSession`, Safe Place phase, video index, and current route are not durable.

**Gap**: no transactional local event/entity store, durable outbox, session recovery checkpoint, or deletion-aware queue. `UserDefaults` and one JSON file are insufficient for high-frequency playback and telemetry records.

### 3.11 Current DEBUG-only controls

**Repository facts**: `WebsiteFeasibilityView`, `SafariExtensionSetupSection`, the Website Feasibility navigation and handoff diagnostics on `AppSelectionView`, and the onboarding reset controls are all `#if DEBUG` only. They must remain excluded from Release unless a later milestone explicitly replaces them with product UI.

### 3.12 Analytics, network, authentication, and backend

**Repository fact**: there is no product analytics layer, HTTP client, Supabase integration, user account system, telemetry queue, remote schema, or backend resource. Screen Time authorization is not participant authentication. YouTube iframe traffic is the only current content network path.

### 3.13 Relevant project documentation

The plan incorporates: `.cursor/rules/mandatory-prompt-verification.mdc`, `docs/AI-Coding-Guardrails.md`, `docs/AI-Change-Report-Protocol.md`, `docs/onboarding-implementation-plan.md`, `docs/Spike-Validation-Report.md`, `docs/Spike-Implementation-Checklist.md`, `docs/Feasibility-Research-Plan.md`, `docs/ios-web-blocking-research.md`, `docs/safari-domain-rules.md`, `docs/investigation-safari-first-navigation.md`, and `THIRD_PARTY_NOTICES.md`. Historical documents contain spike-era or pre-M1 statements; current code and the repository snapshot take precedence.

### 3.14 Gap classification

**Reuse**: root interrupt concept and lifecycle hooks; Safari block page → explicit URL callback; app-shield App Group handoff and extension boundaries; Breathe-first Safe Place flow; vertical pager with one active player; onboarding ownership and derived-step pattern; Repair evaluator and technical protection services.

**Refactor**: split product routing/session concerns from `SpikeAppState`; replace the Boolean route with typed entry requests; replace the spike post-onboarding root with Heal home (routing decision in 27.1); move Safe Place phases/timers out of view-local state; instrument the player path; consolidate lifecycle observation ownership without merging technical sources of truth.

**New components**: root/auth/consent coordinator; entry and session controller; active-time recorder; prompt scheduler and UI; exit flow and feedback UI; content catalog and player adapters; durable research store and outbox; auth/allowlist/installation/consent owners; backend schema, RLS, and idempotent ingestion; protection observation/loss detector; account deletion coordinator; data-quality reconciliation tooling.

**Genuinely open**: everything in section 27.

---

## 4. MVP scope and non-goals

### 4.1 In scope

- Approved-participant email plus numeric verification-code access (section 16.2).
- Versioned consent and age affirmation before sensitive remote collection.
- Normal Heal home.
- Safari-CTA (`safari_block_page`) sessions as the primary study cohort; manual `Enter Safe Place` retained as a product feature with full measurement recording and secondary-cohort analysis; app-shield entries retained with typed provenance but outside the primary study cohort (section 7.3).
- Breathe-first Safe Place session, active-time semantics, and inactivity handling.
- Scheduled in-feed urge prompts and the explicit exit urge/feedback flow.
- Raw content-view and playback measurement for the mixed-source library: YouTube instrumentation first, then the Heal-hosted player as a separate required milestone before external readiness (section 13.5).
- Durable offline local records and idempotent remote collection.
- Relational research model on the selected backend (Supabase candidate), account logout and deletion.
- Protection-state observation with detection-time semantics.
- Internal testing, private TestFlight external testing, study support, and backend-table/CSV validation before any custom dashboard.

### 4.2 Not goals for the first MVP

Tamper-proof blocking or uninstall prevention; a Lockout Timer; user-managed passwords; public App Store distribution; social networking or user-generated content; Chrome CTA parity; advanced recommendations or personalization; notifications; gamification, streaks, or retention mechanics; personal urge-history UI; server-backed protection enforcement; a custom research dashboard before telemetry stabilizes; recording every Safari blocked-page appearance in the first measurement milestone; a workaround for the dedicated Safari protection-test first-navigation issue; a fix for the transient Screen Time `notDetermined` launch observation; the app-shield durable handoff inbox redesign.

---

## 5. Full user journey

### 5.1 Enrollment recommendation

**Recommendation; final wording and ordering require privacy/legal review**

1. Participant receives an individual TestFlight invitation.
2. Before entering an email or starting sensitive collection, Heal shows a concise data/age/study disclosure.
3. Participant affirms age 18+, enters an email, then enters the received numeric verification code (section 16.2).
4. The backend checks the approved-email allowlist independently from TestFlight access.
5. The authenticated user accepts a versioned detailed consent.
6. Heal registers the generated `installation_id`.
7. Existing protection onboarding runs or resumes.
8. Heal opens the normal home screen.

No behavioral or urge records may be uploaded before valid consent. Minimal authentication operations necessarily involve the authentication provider; the disclosure must explain this. If the participant declines consent or does not affirm age 18+, the app must not create or upload study measurements; continued access to an explicitly unmeasured local Safe Place is an open decision (27.3).

### 5.2 Normal icon launch

- Restore local auth/session state, consent state, queued data, and any Safe Place recovery checkpoint; reconcile an interrupted session without claiming precise termination detection.
- With no explicit Safe Place request, show the applicable enrollment/onboarding gate or Heal home. An icon launch by itself is never an entry.
- Refresh protection health without blocking manual Safe Place access; attempt outbox sync only through the sync owner.

### 5.3 Safari intervention

1. Safari DNR redirects a covered page to Heal's custom block page.
2. The participant taps the Safe Place CTA; iOS may show its app-open confirmation.
3. The callback creates a `safari_block_page` entry request.
4. The session controller reconciles any suspended session and handles the request per sections 7–8 (new session on Breathe, or another entry on the active session).
5. For a new session, Continue enters the feed and starts the scheduled feed-prompt clock; the participant watches content and answers or skips prompts; explicit Exit completes the urge/feedback flow and returns to home.

### 5.4 Manual intervention

- `Enter Safe Place` is the primary home action and **must remain available even when protection is disabled, unavailable, or broken** (Confirmed).
- It creates source `manual_in_app` and follows the same Breathe, feed, prompt, and exit semantics.
- Manually initiated sessions are recorded with all approved measurements and analyzed as a separate secondary cohort, not as part of the primary Safari efficacy analysis (section 7.3).

### 5.5 App-shield intervention

- Existing shield functionality may continue to route into Safe Place; an accepted app-shield handoff retains typed source `app_shield`.
- **Confirmed**: `app_shield`-initiated sessions are excluded from the primary first-study cohort and analyses unless separately approved later. The path must never be mislabeled as Safari because a website token was involved.

### 5.6 Offline or expired authentication

**Recommendation**

- A previously authenticated, consented installation continues to provide Safe Place offline; records are written to the durable local store before any upload attempt.
- Expired credentials pause upload and trigger reauthentication outside the active intervention; a temporary auth failure must not discard or block an active session.
- First-time authentication and allowlist verification require connectivity.
- Behavior after explicit logout or participant removal is open (27.3).

---

## 6. Heal home-screen flow

### 6.1 Confirmed scope

Home contains: a primary `Enter Safe Place` action; protection status and a route to Repair when needed; Settings; Send Feedback. It does not include personal analytics history.

### 6.2 Routing

**Repository fact**: `PostOnboardingRootView` currently shows `AppSelectionView`/`SetupView`, and `ContentView` presents Repair before the post-onboarding root whenever unresolved issues exist and the session has not deferred.

**Confirmed requirements**:

- manual `Enter Safe Place` remains available even when protection is disabled or broken;
- explicit Safe Place Exit returns to home;
- protection problems remain visible and Repair remains reachable.

**Open decision** (27.1): whether mandatory post-onboarding Repair presentation is replaced by a home status summary with Repair as an explicit destination, or Repair remains a root gate ahead of home. This changes the existing root-priority contract and requires explicit approval; no implementation agent may change it silently. Recommendation: home status plus explicit Repair route, because a mandatory Repair root would otherwise intercept every post-exit return to home.

Additional recommendations: one product home route as the completed-participant root; reuse `ProtectionRepairEvaluator` and technical services for the status summary; preserve enrollment/onboarding gates before home; keep Safe Place the highest explicit interrupt for eligible participants. Handling of a Safe Place interrupt during incomplete authentication, consent, or onboarding must be resolved in the root-routing milestone, not hidden in a view.

### 6.3 Settings

Eventually: account identity/status (never the code as identity); logout; `Delete Account and Data`; protection configuration and Repair access; consent/privacy information and deletion contact; app/build/support information. Exact information architecture is a later UI decision.

### 6.4 Send Feedback

Separate from the structured exit feedback. Transport and support workflow are open (27.1). If remote free text is used, it is sensitive study data under the same consent, outbox, access-control, and deletion boundaries.

---

## 7. Safe Place entry definitions

### 7.1 Entry

**Confirmed**

A Safe Place entry is recorded whenever Safe Place is explicitly presented because Heal accepts an explicit request from:

- `safari_block_page`
- `app_shield`
- `manual_in_app`
- `unknown`, only when source cannot be safely reconstructed

Rules:

- Opening Heal from its icon and reaching normal home is not an entry.
- Returning to an already-active Safe Place after less than three minutes away is a session resume, not automatically a new entry.
- A second explicit route while the same session remains active creates a second entry linked to that same session; acceptance of the request counts even though the visible phase is preserved rather than reset.
- A future Safari-extension milestone will record every blocked-page appearance; that event is separate from a Safe Place entry (section 21).

### 7.2 Entry envelope and identity

**Recommendation**

Replace Boolean route state with a typed, uniquely identified request containing: client-generated `entry_id`; source enum; client occurrence timestamp (UTC); installation ID; route/transport correlation ID when available; received-by-app timestamp; optional source-specific metadata containing no URLs or browsing history; schema version. The session controller serializes intake and attaches each in-app request object once.

Source-specific identity limits:

- Manual entry receives an ID before routing and is idempotent by that ID.
- An app-shield marker carries a UUID usable for transport correlation. The single-slot overwrite limitation is documented in section 3.6 and is acceptable for the Safari-first MVP because app-shield sessions are outside the primary study cohort.
- The current Safari production CTA is a fixed `heal://safe-place` URL with no correlation ID. Each accepted `onOpenURL` callback is a distinct explicit route unless a later, separately reviewed transport adds identity. Do not collapse rapid callbacks heuristically; that could erase real re-entry data. A client-generated `entry_id` makes the local record unique but cannot prove whether iOS redelivered a fixed callback.

### 7.3 Source reconstruction, study cohorts, and functional verification

**Confirmed — initiating-entry cohort rule**

Cohort assignment for a Safe Place session uses the **initiating entry**: the entry that begins the session (the first entry attached when the session starts on Breathe). Later re-entries during the same active session are always preserved as raw entry records with their own sources and never discarded to force a single-source story. Multi-entry or multi-source sessions remain analyzable by every entry source and by initiating source.

| Initiating entry source | Recording | Cohort / analysis |
| --- | --- | --- |
| `safari_block_page` | Full research recording | **Primary study cohort** and primary efficacy analysis |
| `manual_in_app` | Full research recording with all approved measurements | **Secondary cohort** — separate from primary efficacy |
| `app_shield` | Full research recording with typed provenance | Outside the primary first-study cohort and analyses unless separately approved later |
| `unknown` | Full research recording when reconstruction is required | Available for data-quality investigation; **excluded from primary efficacy analysis** |

Source reconstruction:

- Production Safari Safe Place callback (`heal://safe-place`): `safari_block_page`.
- Home primary action: `manual_in_app`. Manual `Enter Safe Place` remains a required product feature.
- Accepted app-shield handoff marker: `app_shield`.
- Legacy, corrupt, or ambiguous routes: `unknown`, only when source cannot be safely reconstructed.

**Confirmed — `functionalVerification` presentation mode**

The onboarding/functional callback `heal://safe-place?source=safariProtectionTest` continues to open Safe Place without creating research data. Routing must attach an explicit operational presentation context (recommended name: `functionalVerification`; final Swift type name is an implementation detail) that is distinct from a research entry request.

Ownership and behavior contract:

- Existing `SafariProtectionTestStore` validation and pass-marking behavior remains.
- Safe Place UI may be reused for functional verification.
- The session controller / research boundary must refuse research recording for this presentation context: no research entry, session, episode, active-time segment, urge prompt, measurement, content-view record, playback record, exit feedback, protection observation, outbox row, or research telemetry event is created.
- Functional verification is not assigned to any study cohort.
- Research prompt scheduling and study exit-feedback flows are disabled in this mode.
- At most, a separately approved operational diagnostic event outside the research dataset may be recorded.
- Ordinary production `heal://safe-place` behavior remains unchanged and continues to create typed `safari_block_page` research entry requests.

---

## 8. Session and episode state machine

### 8.1 Active Safe Place session

**Confirmed**

- A session begins when Safe Place starts on the Breathe screen.
- Only active Safe Place time counts; background, inactive, locked-screen, and other-app time do not.
- Return after less than 3 minutes without explicit Exit resumes the same session; absence of exactly 3 minutes or more ends it.
- The next entry after a timeout starts a new session on Breathe.
- Explicit Exit ends the session immediately after the exit flow completes; return after explicit Exit always starts a new session, even after seconds.
- End reasons: `explicit_exit`, `inactivity_timeout`, `unknown`.

### 8.2 Proposed states

One app-scoped session controller owns research Safe Place states: `idle`, `starting(entry)`, `breathe`, `feed`, `scheduledPrompt`, `exitUrge`, `exitFeedback`, `suspended(previousState, inactiveStartedAt)`, `ending`, `ended`. Views render controller state and send intents; they do not calculate session boundaries.

**Functional-verification boundary**: a `functionalVerification` presentation (section 7.3) must not enter the research session state machine. The root/routing owner may reuse Safe Place UI under that operational context, but the session controller must not start a research session, attach research entries, run study prompt scheduling, or emit research telemetry for it.

### 8.3 Transitions

- `idle + explicit entry`: create session ID; attach entry; select or create episode per the approved episode scope; start Breathe and a Breathe active segment.
- `active session + explicit entry`: create another entry on the same session; do not reset to Breathe; do not create a second session.
- `active + scene inactive/background`: end the current active segment; pause all active clocks; durably checkpoint prompt selection and state; enter `suspended`.
- `suspended + return before 180 seconds`: resume the same session and exact phase; preserve a visible prompt and selected value.
- `suspended + return at or after 180 seconds`:
  - a visible prompt finishes as skipped due to inactivity;
  - a due-but-never-shown scheduled prompt finishes as `notShownSessionEnded`, not participant Skip;
  - a shown prompt preserved behind prior content finishes as skipped due to inactivity, preserving that it had been shown;
  - close the session with `inactivity_timeout`; do not restore exit feedback; route the next explicit entry to a new Breathe session.
- `suspended + explicit entry request`: serialize timeout reconciliation before entry attachment; absence under 180 seconds resumes the same phase and attaches a new entry; absence at or over 180 seconds closes the old session, then creates a new session and entry on Breathe. Never let `.onOpenURL` and `scenePhase` callbacks independently create two sessions.
- `active + completed explicit exit feedback`: close with `explicit_exit`; persist final state and outbox records; route to home.

### 8.4 App termination

iOS termination cannot always be observed at the moment it occurs. The durable checkpoint preserves: last active timestamp; inactive/background start when observed; current phase; active-time counters; visible prompt and selection; pending exit state; latest persisted entity/event sequence.

On a later launch the controller reconciles the checkpoint: it records `inactivity_timeout` when evidence shows the absence reached three minutes, and `unknown` when required evidence is missing or corrupt. It must not claim an exact termination timestamp. Lifecycle changes, handoff intake, URL intake, and manual entry intents all enter one serialized controller; callback arrival order is not itself the business rule.

**Recommendation**: for inactivity closure, store separately the last active timestamp, inactivity start, logical timeout boundary, and detection/reconciliation timestamp. Do not equate detection time with last active use.

### 8.5 Intervention episode

**Confirmed**

- A new session beginning less than 10 minutes after the previous session ended belongs to the same episode.
- A gap of exactly 10 minutes or more starts a new episode.
- Sessions and entries remain individually stored even when grouped; rapid re-entry is never averaged away.

### 8.6 Episode ownership

**Open decision** (27.1): whether episodes group sessions per authenticated user across installations or per installation. Recommendation: preserve raw session boundaries and IDs so episodes can be rebuilt; prefer user-scoped canonical assignment on the backend; label any local offline grouping provisional; version the grouping algorithm.

---

## 9. Active-time ownership

### 9.1 Single owner

**Recommendation**: the session controller owns one active-time recorder. Views and player wrappers report phase transitions and playback callbacks but maintain no competing timers.

### 9.2 Time sources

- UTC wall-clock timestamps for correlation; event-time timezone offset (and IANA timezone when available) for local-day analysis.
- Monotonic clock for in-process durations; persist accumulated durations plus wall-clock checkpoints for recovery.
- Never derive active duration solely from session start minus session end. Server receipt time is separate from client occurrence time.

### 9.3 Active phases

Raw active segments for: Breathe; feed content; urge prompt; exit urge prompt; exit detailed feedback. Derived totals: total active session time and per-phase active durations. Playback time is not feed active time; it comes from player callbacks.

### 9.4 Pause rules

All active clocks pause when the scene is inactive/backgrounded, the device is locked, another app owns the foreground, or Safe Place is not the visible product phase.

The scheduled prompt interval uses active feed-surface time only: it advances while a feed content page is visible and Heal is active — including loading, buffering, user-paused playback, or player failure — while actual playback time remains a separate player-derived metric. Time on a prompt page does not advance the interval.

---

## 10. Breathe-screen behavior

### 10.1 Confirmed UI

- The session starts on the Breathe screen; its active duration is tracked separately.
- An optional English urge question appears in a row above `Continue`; scale `0–10`; higher means a stronger urge.
- The question never blocks feed entry; there is no separate Skip button.
- `Continue` with a selected value records an answered measurement; `Continue` without a value records an explicit skipped prompt.

### 10.2 Data semantics

One prompt record exists even when skipped: type `breathe_entry`; sequence within session; shown/finished timestamps; active session offsets; outcome `answered`/`skipped`; completion method `continue_button`; a reference to the linked measurement when answered (section 14.7). An answered value creates one `urge_measurements` row; a skip never creates a fake numerical value. The completion timestamp starts the 30-second exit-urge interval (section 12.2).

### 10.3 Feed transition

On Continue: finish the Breathe prompt; close the Breathe active segment; start the feed phase and feed active segment when the first feed content page becomes visible, independent of player readiness; initialize Prompt 1's interval at zero active feed time. The scheduled feed timer never begins when the session or Breathe screen first appears.

---

## 11. Feed prompt scheduler state machine

### 11.1 Confirmed schedule

Use active feed time only:

1. Prompt 1 is due after 60 seconds in the feed.
2. Prompt 2 is due 90 seconds after Prompt 1 finishes.
3. Prompt 3 is due 120 seconds after Prompt 2 finishes.
4. Prompt 4 is due 120 seconds after Prompt 3 finishes.
5. No further scheduled prompts occur in that session.

"Due" means the interval elapsed and the prompt is waiting to be presented. Each later interval begins only when the previous prompt has finished, not when it became due.

### 11.2 Scheduler states

Per scheduled prompt: `waiting(intervalStart, requiredActiveFeedDuration)`, `dueWaitingForForwardTransition`, `visible(selection?)`, `preservedBehindPreviousContent(selection?)`, `finishedAnswered`, `finishedSkipped`, `notShownSessionEnded`. The scheduler belongs to the session controller or a subordinate single owner, never to feed cells.

### 11.3 Becoming due

When the required interval elapses: store the interval start and due time; stop counting that interval; keep the current video uninterrupted; wait for the next forward content transition. The next scheduled interval cannot begin before the current prompt finishes.

### 11.4 Intercepting forward navigation

When due and the next forward transition occurs: capture the intended next content target; show the urge-prompt page instead; store shown timestamp and active offsets; after completion, continue to the intended target. Backward navigation does not satisfy the forward-transition requirement.

The controller serializes due-threshold and navigation intents: if the interval reaches its threshold at or before the instant of a forward intent, due-state wins and the transition is intercepted; otherwise navigation proceeds. Exactly-at-threshold behavior requires a deterministic boundary test.

### 11.5 Prompt interaction

**Confirmed**

- select `0–10`, then Continue: answered, method `continue_button`;
- select `0–10`, then swipe forward: answered, method `forward_swipe`;
- explicit Skip button: skipped, method `explicit_skip`;
- swipe forward with no selection: skipped, method `forward_swipe`;
- swipe backward: no completion.

A backward swipe preserves the prompt record and selected value, leaves the prompt logically in the navigation sequence so it can be completed later, and does not start the next scheduled interval.

### 11.6 Required prompt fields

Preserve: prompt ID, session ID, type; scheduled sequence `1...4`; interval start (wall timestamp and active-feed offset); required active interval; due timestamp and offset; shown timestamp; active session and feed time when shown; finished timestamp and offsets; measurement reference when answered; outcome; completion method; intended next content/view ID; schema version.

### 11.7 Background behavior

While a prompt is visible:

- Return before 3 minutes: resume the same prompt with selection intact.
- Absence of exactly 3 minutes or more: finish as skipped with an inactivity-specific completion reason; close the session with `inactivity_timeout`; do not start a later interval; the next entry starts on Breathe.

In other scheduler states:

- `waiting`: the active-feed interval pauses; return under three minutes resumes the same accumulated time.
- `dueWaitingForForwardTransition`: remains due across a return under three minutes; do not show until the next forward transition.
- `preservedBehindPreviousContent`: selection and logical page position are retained under three minutes.
- At an absence of exactly three minutes or more, session closure applies the outcomes in section 8.3; a merely waiting future prompt is never fabricated as shown or skipped.

The analytics schema must distinguish user-explicit Skip, forward-without-answer, exit interception, and inactivity closure.

### 11.8 Feed end/repeat dependency

**Open decision** (27.1): the current feed is finite, and a due prompt requires a next forward transition, so end-of-catalog and repeat ordering must be resolved before scheduler implementation. Do not silently choose looping, reshuffling, or termination.

---

## 12. Exit Safe Place flow

### 12.1 Exit intent while an urge prompt is visible

**Confirmed**

- A selected value is saved; no selected value is recorded as Skip.
- That prompt serves as the exit urge measurement; do not show another urge prompt.

**Recommendation**: record completion method `exit_action` so the exit path remains distinguishable. (Open decision 27.1 covers final completion-method naming for exit-completed prompts.)

### 12.2 Exit intent while no urge prompt is visible

**Confirmed**

- Show an exit urge question only when at least 30 seconds have passed since the previous urge prompt finished; otherwise omit it.
- The interval starts when the previous prompt finished — via answer + Continue, answer + forward swipe, explicit Skip, unanswered forward swipe, or the Breathe prompt completion/skip — never when a prompt first appeared.
- Exactly 30.000 seconds satisfies "at least 30 seconds" (inclusive `>=`), once the clock type is approved.
- If shown, the exit prompt uses type `exit`, the same `0–10` direction, and explicit answer/skip semantics.
- When the exit urge is omitted, continue directly to detailed feedback; do not end the session early or fabricate a skipped exit prompt.

**Open decisions** (27.1): whether the 30 seconds use active Safe Place time or wall time (recommendation: active time), and the exact controls on a standalone exit prompt (recommendation: Continue plus a visually distinct explicit Skip, no feed-navigation swipe).

### 12.3 Due or preserved prompts at Exit

**Recommendation**

- Exit while a scheduled prompt is due but not shown: treat it as not shown/session ended, not participant Skip; apply the exit-urge rule; preserve the due record.
- Exit while a shown prompt is preserved behind previous content: restore that prompt with its selection and use it as the exit measurement, preventing a second simultaneous urge opportunity. MVP-0 must confirm this (27.1).

### 12.4 Detailed feedback

**Confirmed**

After the urge step (current/preserved prompt, shown exit prompt, or intentionally omitted exit prompt), show an optional single-selection screen:

- `The videos helped me calm down`
- `I still feel a strong urge`
- `I wanted different content`
- `Something was confusing`
- `Other` (may reveal an optional free-text field)

Requirements: single selection only; a visibly differentiated explicit `Skip`; record shown/finished timestamps and active duration; preserve answer or Skip and completion method; limit and protect free text as sensitive data.

### 12.5 Completion

After answer or Skip: finish the feedback record; end the session with `explicit_exit`; persist/queue final records atomically; return to Heal home.

### 12.6 Abandoning exit flow

If the participant leaves without completing explicit Exit and does not return within three minutes:

- do not restore the prior exit feedback on next launch;
- if detailed feedback was shown, record the attempt as abandoned by inactivity, not user Skip, unless Skip was tapped;
- if the participant left during an exit-urge prompt before feedback was shown, close that prompt by the visible-prompt inactivity rule and do not fabricate a feedback attempt;
- end the session with `inactivity_timeout`; the next entry begins on Breathe.

---

## 13. Video and content architecture

### 13.1 Current baseline

The repository has a 14-ID YouTube catalog, vertical SwiftUI pager, and one active WKWebView embed (section 3.4). Usable for visual-flow prototyping; cannot produce the required playback facts.

### 13.2 Recommended boundaries

- **Content catalog owner**: stable internal `content_id`, catalog version, source type, provider reference, duration metadata, availability, ordering inputs; bundled fallback catalog for offline intervention.
- **Feed coordinator**: owns content sequence and forward/back navigation semantics; coordinates prompt insertion.
- **Player adapter protocol**: presents one item; emits start, pause, resume, seek where allowed, end, failure, and progress; writes no telemetry directly.
- **Playback recorder**: converts player callbacks plus scene/visibility state into raw view and segment records.
- **Telemetry/research store**: persists records and outbox transactions.

### 13.3 Content source types

**Confirmed**: the first study content library mixes `youtube` and `heal_hosted`. Source type is stored on the catalog item and playback record, never inferred from URL text at analysis time.

### 13.4 Raw playback requirements

Per content opening/view: user and installation; session context; session `initial_entry_id` and nullable `latest_entry_id_at_open`; stable content ID and catalog version; source type; open/close timestamps; feed sequence position; navigation direction; repeat ordinal; previous and intended next content where relevant.

Per playback segment: segment ID and parent view ID; playback start/end timestamps; actual seconds played; start/end media position when available; content duration used for percentage; completion/end reason (forward skip, backward navigation, replay, failure, background, exit).

Derived later: average/median watch time per item; completion rate; unique users per item; repeat views; user behavior by unique content; relationship between content exposure/playback and later urge change.

### 13.5 Staged implementation

**Confirmed sequencing** (section 24): first stabilize content IDs/catalog and the feed-navigation contract; then instrument the current YouTube path sufficiently for the approved metrics; then implement scheduled prompts on that stable contract; then implement the Heal-hosted player as a **separate required milestone (MVP-13)** before MVP-15 / external TestFlight readiness under the current confirmed mixed-source plan.

MVP-13 becomes optional only after a later explicit product decision to run the first study with YouTube-only content. Until that decision exists, mixed-source content is required for the currently planned external-study build, and MVP-15 must not treat MVP-13 as skippable.

`YouTubeEmbedWebView` currently cannot expose actual playback time or completion; the instrumentation milestone must evaluate an approved YouTube IFrame API integration or another compliant approach. `didFinish` is never recorded as playback start or completion. Heal-hosted storage/CDN, signed URLs, caching, media format, and player implementation remain open (27.2), as do exact ordering, selection, repeat, and fallback behavior (27.1); the first study should favor a versioned, reviewable curated policy.

---

## 14. Analytics definitions

### 14.1 Purpose

Analytics exists to evaluate the intervention and data quality. It is not a user-facing personal history system.

### 14.2 One telemetry owner

**Recommendation**: one app-level research/telemetry owner backed by a durable store. Views and player wrappers emit typed intents/callbacks; they never send network requests or maintain their own queues.

### 14.3 Raw before derived

Averages, medians, buckets, improvement, and trend values are rebuildable queries/views. They never replace raw records.

### 14.4 Identifiers

Client-generated stable UUIDs for offline creation: event, installation, session, entry, prompt, measurement, content view, playback segment, exit feedback, protection observation/loss. The auth provider's stable `user_id` is the user identity; verification codes are temporary credentials and never IDs.

`installation_id` is generated before any durable study entity exists. Local pre-auth records, if MVP-0 permits them, are installation-bound with no fabricated user identity and remain quarantined from upload until explicitly linked to an authenticated, consented user; otherwise study measurement stays disabled before authentication/consent.

### 14.5 Event-time fields

Each uploadable record includes: client occurrence timestamp (UTC); monotonic/accumulated active offset where applicable; timezone offset and optional IANA timezone; installation sequence number; schema version; server receipt timestamp (server-assigned); app/build and platform version where needed for data quality.

### 14.6 Typed events

The relational model is canonical; an event ledger may carry transitions such as: entry recorded; session started/suspended/resumed/ended; phase segment started/ended; prompt interval started/due/shown/finished; content view opened/closed; playback segment recorded; exit feedback shown/finished; protection state observed/loss detected; consent accepted/withdrawn; upload/deletion status. Names and payloads are frozen in the data-contract milestone before source implementation.

### 14.7 Canonical data sources

**Confirmed principle — no parallel writable sources of truth**:

- `urge_measurements` is the canonical numerical urge value. `urge_prompts` stores prompt lifecycle/outcome and an optional measurement reference, never a second independently writable selected value.
- Relational domain rows (entries, sessions, episodes, segments, prompts, measurements, views, playback segments, feedback, observations) are the research source of truth.
- The local outbox and the remote ingestion/event ledger are transport, idempotency, receipt, and audit mechanisms — not a competing canonical copy of domain data.
- Raw protection observations are the canonical observations; a protection-loss detection is a derived transition record linked to the relevant observations.
- Cached session duration totals are derived from raw segments and must reconcile against them.
- Ephemeral view state (current selection before submission, load spinners) never becomes a second persistence path.

---

## 15. Primary and secondary metrics

### 15.1 Primary metric

**Confirmed**

A session is eligible for urge-improvement calculation only when it contains at least two answered numerical urge measurements. Order answered measurements by within-session occurrence/finish order, using active-session offset plus installation sequence as the deterministic tie-breaker. The first answered value does not have to be the Breathe prompt.

`urge_improvement = first_answered_urge - last_answered_urge`

Positive means improvement; zero, no measured change; negative, a stronger reported urge.

**Primary efficacy cohort** (section 7.3): only sessions whose initiating entry source is `safari_block_page`. Secondary-cohort (`manual_in_app`-initiated) sessions use the same raw calculation for comparative analysis but are reported separately and must not be pooled into the primary efficacy denominator without an explicit later decision. Sessions initiated by `app_shield` remain outside the primary first-study cohort unless separately approved. Sessions initiated by `unknown` remain available for data-quality investigation and are excluded from primary efficacy analysis. Multi-entry sessions keep every raw entry; cohort membership still follows the initiating entry only.

Retain: every prompt and raw answered measurement; answered and skipped counts; first/last measurement IDs and times; active time between first and last answered measurements; total active session time; source/type/timing of every measurement; initiating entry source and every subsequent entry source. For three or more answered measurements, preserve data for later trend/slope analysis against active session offset; never precompute only a slope.

`functionalVerification` presentations create no measurements and no research sessions (section 7.3).

### 15.2 Correlations required

Support analysis against: total active session duration; active feed duration; Breathe duration; prompt/feedback time; content opened; actual playback time; content IDs and source types; initiating entry source, every entry source, and multi-entry/multi-source session status; cohort label (primary Safari / secondary manual / non-primary); episode and rapid-return context.

### 15.3 Secondary behavior metrics

Derivable from raw records, filterable by initiating-entry cohort: Safe Place entries; entries per session; sessions per episode; sessions per active day; entries per day; active days per week; users with 1, 2, 3, or more daily entries; time between entries; time between sessions; rapid returns; repeated use within one episode; average and median active session duration; Breathe, feed, urge-prompt, and exit-feedback active durations; content openings; forward/backward navigation; repeat views; prompt shown/answered/skipped rates; explicit Exit versus inactivity timeout; behavior by entry source. Manual secondary-cohort rates must remain separable from the primary Safari cohort.

### 15.4 Intervals and distributions

Keep exact source timestamps; compute distributions, percentiles, medians, and counts. Suggested analysis buckets: `< 5 minutes`; `5 to < 10 minutes`; `10 to < 30 minutes`; `30 minutes to < 6 hours`; `6 to < 24 hours`; `24 hours or more`. These are reporting buckets only; they do not change the 3-minute session or 10-minute episode definitions.

### 15.5 Denominators

Every dashboard/export names its denominator (prompts shown; all scheduled prompts created; eligible sessions in the primary Safari cohort; eligible sessions in the secondary manual cohort; all recorded sessions; participants with at least one active day). Skipped, not shown, abandoned, and upload-missing records are never mixed into one unlabeled rate. Primary efficacy exports must not silently include `manual_in_app`, `app_shield`, or `unknown` initiating sessions.

---

## 16. Backend and authentication architecture

### 16.1 Backend recommendation

Use Supabase Auth plus PostgreSQL/Supabase as the MVP candidate, subject to a dedicated architecture/security review. This plan does not create or approve a Supabase project. Provider-specific references in later milestones are conditional on that approval; if Supabase is rejected, the affected milestones are re-planned against the selected provider — no agent may mechanically substitute another service.

### 16.2 Authentication

**Confirmed**

- The user enters an email, then receives and enters a **numeric one-time verification code**.
- The code is temporary and is not the user ID; the auth provider returns the stable internal `user_id`.
- No user-managed password exists in the MVP.
- Only approved study-participant emails may proceed; TestFlight invitation and backend allowlist are separate controls.
- Provider constraints may still require technical validation, but agents must not silently replace the confirmed code-entry UX with a magic-link flow.

### 16.3 Authentication state ownership

**Recommendation**: one `AuthSessionStore`-style owner restores provider session/token state; exposes authenticated, refreshing, expired, logged-out, and blocked states; refreshes tokens; coordinates reauthentication; exposes the stable `user_id`; never exposes the verification code beyond the immediate verification action; and notifies sync ownership without performing telemetry writes. Root routing reads this owner; views trigger actions and display state.

### 16.4 Participant allowlist ownership

The selected backend owns an admin-only allowlist: normalized approved email or an approved privacy-preserving lookup; participant status; invitation/enrollment timestamps; optional cohort; removal/withdrawal status; linked `user_id` after enrollment. Research event rows use `user_id`, not email. RLS prevents participants from reading the allowlist or other participants' data. The exact enforcement mechanism (Auth hook, Edge Function, or controlled enrollment endpoint) is open pending backend review (27.3).

### 16.5 Installation registration

- One `installation_id` is generated when app-container installation state is first created, before any durable study entity, and later registered to the authenticated `user_id`.
- Reinstalling or using another device creates a new installation linked to the same user.
- A Keychain-only identifier that silently survives reinstall must not be the installation identity; auth token storage may use provider-recommended secure storage.
- Store app build, OS, and device-class data only to the minimum needed for quality/support.

### 16.6 Token/session lifecycle

First login and allowlist check require network. Tokens restore/refresh through one owner. Sync pauses when authentication cannot be refreshed; the intervention remains locally available for a previously enrolled, consented installation under the recommended offline policy. Reauthentication UI appears outside an active Safe Place session unless continuing is impossible. The server rejects writes for deleted, withdrawn, removed, or mismatched users/installations.

### 16.7 Logout

Logout revokes/clears the local auth session per provider capability, stops uploads, prevents another user from inheriting queued records, and preserves or purges local user-bound data according to an explicit approved policy. Whether logout is offered mid-study and whether it purges unuploaded records are open (27.3).

### 16.8 Offline behavior

Existing enrolled participant: local Safe Place and durable measurement continue. New participant: cannot complete code verification/allowlist without network. Auth expired: queue locally, retry refresh later. Content: a bundled/previously cached fallback policy is required so network loss cannot make Safe Place empty; exact behavior is open (27.2).

---

## 17. Consent, privacy, and account deletion

### 17.1 Consent content

Before sensitive remote collection, explain in English: what data is collected (urge measurements; entries, sessions, episodes, and timing; content/video interaction and playback; exit feedback and optional free text; protection-state observations); why it is collected — to evaluate whether the intervention helps reduce urge; that Heal does not intend to collect browsing history or arbitrary visited URLs; that data is sent to a remote backend; the 18+ age requirement; that Heal is not a substitute for professional treatment or emergency help; and how to request deletion.

### 17.2 Consent record

Store: user ID; consent document/version; presented locale; accepted timestamp; age affirmation; app build; withdrawal/deletion state. No behavioral upload before valid consent. Consent changes are versioned; historical text/versions are never mutated invisibly.

Required negative states:

- `declined`: no study measurement creation/upload; show reviewed next steps.
- `underage_not_eligible`: no study measurement creation/upload.
- `withdrawn`: stop new measurement/upload; begin the reviewed withdrawal/deletion path.
- `new_version_required`: pause new remote collection until the approved re-consent policy completes.

Whether a declined, underage, or withdrawn person may use an explicitly unmeasured local Safe Place is open (27.3).

### 17.3 Legal status

Consent, privacy, disclaimer, retention, deletion, and emergency wording require privacy/legal review before external distribution. This document is not approved legal advice.

### 17.4 Retention

**Confirmed interim product direction; final legal policy remains open (27.5)**

- No fixed retention expiry has been selected.
- Data is retained while the account remains active and until deletion is requested in-app or by contacting Heal.
- Do not invent a fixed expiry in code, database jobs, or copy without approval.

### 17.5 Delete Account and Data

Provide an in-app path. Subject to legal review, deletion covers: the authentication account; email/auth and allowlist linkage as legally permitted; study profile and consent records as legally permitted; installations; episodes, sessions, and entries; active segments; prompts and urge measurements; content views and playback segments; exit feedback and free text; protection observations/detections; queued/outbox records and derived analytics.

### 17.6 Deletion workflow recommendation

1. Deliberate confirmation and, when needed, recent authentication.
2. Authenticated deletion request to a privileged server function, idempotent via a client-generated request ID; a lost acknowledgement retries safely.
3. Server-side deletion tombstone/status before child-data deletion; the tombstone applies across all installations, each honoring completed deletion/withdrawal on next contact.
4. Stop ingestion for the user and installations; delete research rows in a controlled transaction/job; delete or anonymize legally required operational records per reviewed policy; delete the auth account last or through a coordinated privileged path.
5. Acknowledge, purge local user-bound records/outbox, and prevent delayed queued events from recreating deleted records.

If offline, the UI distinguishes a locally queued request from server-confirmed deletion; final offline deletion behavior is open (27.4). The local-store milestone must define iOS file protection and backup exclusion for sensitive queued/research data; transport encryption alone is insufficient.

---

## 18. Proposed relational data model

A proposal for review, not a migration. Use UUID primary keys, UTC timestamps, explicit foreign keys, check constraints, RLS, schema versions, and server receipt timestamps. Canonical-source rules in section 14.7 apply throughout.

### 18.1 Authentication and study access

- **`auth.users`** — provider-owned stable authenticated identity.
- **`study_participants`** — allowlist/admin enrollment: approved email lookup; status, cohort, invited/approved/removed timestamps; linked `user_id` after enrollment; admin/service-role access only.
- **`study_profiles`** — PK/FK `user_id`; study status; created/withdrawn/deletion timestamps; no duplicated email for analytics.
- **`study_consents`** — immutable consent instances: `user_id`, version, locale, age affirmation, accepted/withdrawn timestamps, app build.

### 18.2 Installations

- **`installations`** — client-generated `installation_id`; `user_id`; created/registered/last-seen/revoked timestamps; app/build/OS quality metadata; client schema version. One user may have many installations.

### 18.3 Episodes, sessions, entries, and time

- **`intervention_episodes`** — `episode_id`; `user_id`; start/end timestamps; grouping scope and algorithm version; created/recomputed timestamps.
- **`safe_place_sessions`** — `session_id`; `user_id`, `installation_id`, nullable `episode_id`; start timestamp; last-active, inactivity-start, logical-end, and end-detected timestamps where applicable; end reason; cached total active and per-phase durations (derived from raw segments with reconciliation checks); client and schema versions. Cohort queries join the initiating entry (earliest entry for the session, or an explicit `initiating_entry_id` FK if added for query convenience) and filter by that entry's source per section 7.3; never overwrite or discard later entry rows to force a single source.
- **`safe_place_entries`** — `entry_id`; `session_id`, `user_id`, `installation_id`; source enum; occurrence and app-receipt timestamps; transport correlation ID; schema version. Many entries per session; every re-entry is retained.
- **`safe_place_active_segments`** — segment ID; session ID; phase enum; client start/end timestamps; measured active duration; installation sequence number; end/correction reason.

`functionalVerification` presentations create no rows in any of these tables (section 7.3).

### 18.4 Urge prompts and measurements

- **`urge_prompts`** — prompt ID and session ID; type (Breathe, scheduled, exit); scheduled sequence; interval start, required active interval, due, shown, and finished fields; active session/feed offsets; outcome (answered, skipped, not shown, abandoned); completion method; optional reference to the linked measurement; intended next content view; schema version. The prompt row never carries an independently writable selected value.
- **`urge_measurements`** — measurement ID; prompt ID and session ID; value with check constraint `0 <= value <= 10`; answered timestamp; active session/feed offsets; measurement source/type. Canonical numerical urge value; only answered prompts create rows.

### 18.5 Content and playback

- **`content_catalog_versions`** — version ID; published/retired timestamps; ordering-policy identifier; environment.
- **`content_items`** — stable content ID; catalog version; source type `youtube`/`heal_hosted`; provider reference; research-scoped curation metadata; expected duration; availability state.
- **`content_views`** — view ID; session/installation/user/content IDs; session initial-entry ID and nullable most-recent-entry ID at open; opened/closed timestamps; feed position; navigation direction; repeat ordinal; previous/next view references; close reason.
- **`video_playback_segments`** — segment ID and content view ID; playback start/end; actual seconds played; media start/end position; duration basis; completion flag; end reason; source type snapshot.

### 18.6 Exit feedback

- **`exit_feedback`** — feedback ID and session ID; shown/finished timestamps and active duration; selected single option; optional `other_text`; answered/skipped/abandoned outcome; completion method; schema version. Free text requires stricter access and logging controls.

### 18.7 Protection observations

- **`protection_state_observations`** — canonical observations: observation ID; user/installation; protection type; observed state; observed timestamp; prior known state and most recent known healthy timestamp; lifecycle trigger; last session/episode snapshot; schema version.
- **`external_protection_loss_detections`** — derived transitions linked to observations: detection ID; linked observation; user/installation; protection type; detection timestamp; prior known state; most recent known healthy observation; last Safe Place session ID; last episode ID; last session end timestamp; recovery/deduplication fields. The detection timestamp is never labeled disablement time.

### 18.8 Transport, ingestion, and deletion identity

- **`telemetry_events`** (ingestion ledger) — globally unique `event_id`; user/installation; event type; entity ID/reference; installation sequence; per-entity mutation revision (separate from payload schema version); payload/schema version; client timestamp; server receipt timestamp; idempotency constraint. Transport/audit only; not a competing canonical copy (14.7).
- **`sync_receipts`** or RPC response — batch/event IDs; accepted/duplicate/rejected status; server timestamps and error code.
- **`account_deletion_requests`** — client-generated idempotent request ID/user ID; requested, acknowledged, completed timestamps; state and reviewed failure code; no sensitive free-text diagnostics.
- **`general_feedback`**, only if Send Feedback uses the research backend — feedback ID/user/installation; submitted timestamp; optional category/text; app/build context; identical consent, access, retention, and deletion rules as other sensitive free text. If a separate support provider is used instead, document that data flow and policy.

### 18.9 Relationships and access

`auth.users 1—1 study_profiles`; `auth.users 1—many study_consents / installations / episodes`; `episodes 1—many sessions`; `sessions 1—many entries / active segments / urge prompts / content views`; `urge prompts 0—1 measurement`; `entries 1—many or 1—zero content-view attribution links` via initial/latest entry fields; `content views 1—many playback segments`; `sessions 0—1 completed exit feedback record` with abandoned attempts preserved per schema design; `installations/users 1—many protection observations/detections`.

Participants insert/update only through narrow RLS/RPC rules for their own user/installations and have no broad read access to research tables. Dashboard/service-role access is separate and audited.

---

## 19. Offline outbox and sync design

### 19.1 Repository-informed options

`UserDefaults` suits small flags, not high-volume ordered telemetry; the existing atomic JSON pattern is weak for concurrent transactional entity/outbox updates. Candidates for the technical-decision milestone: SwiftData; Core Data; direct SQLite through a minimal reviewed wrapper; a bounded append-only file plus index only if it meets transaction/recovery requirements.

**Open decision** (27.4): no exact local technology is approved. Recommendation: the smallest database-backed option supporting one-writer isolation, atomic domain-record-plus-outbox writes, migrations, deterministic tests, and deletion; no new dependency unless the reviewed platform option is inadequate.

### 19.2 Ownership

One actor/serialized store owns local research entities, the durable session checkpoint, outbox rows, installation sequence numbers, acknowledgement state, and local deletion. One sync coordinator owns networking, auth token use, retry, batching, and receipts.

### 19.3 Write path

For each meaningful transition: generate entity/event IDs client-side; in one local transaction, update the domain entity and append its outbox item; return success only after durable commit; let the sync coordinator upload later. Views never wait on or call a remote analytics endpoint.

### 19.4 Retry and acknowledgement

- Bounded exponential backoff with jitter for transient failures; pause for no connectivity, invalid/expired auth, participant removal, or deletion.
- Batch within payload limits; preserve installation sequence order where parent/transition order matters.
- The server transaction validates user/installation and schema; unique `event_id` makes retries idempotent; per-entity mutation revision is compared before changing mutable snapshots so an older delayed revision cannot overwrite a newer terminal state.
- Local rows are acknowledged only after server commit/receipt; duplicate acknowledgement is success; rejected schema/auth rows stay distinguishable from transient failures.
- Aggregate upload health goes to internal diagnostics; sensitive payloads never appear in logs.

### 19.5 App termination and background execution

Correctness depends on durable local commit, not last-second upload. Sync may run on launch, foreground, suitable background opportunities, and internal diagnostics; no milestone claims guaranteed immediate delivery.

### 19.6 Ordering

Client-generated IDs so children reference parents offline; per-installation monotonic sequence; immutable transition events where practical; a monotonic per-entity mutation revision where a mutable snapshot is necessary; payload schema version as a separate concept; server receipt time. The backend accepts idempotent appends and revision-guarded upserts without fragile arrival-order requirements: revision 3 arriving before revision 2 leaves revision 3 authoritative while retaining audit evidence. Derived episode/metrics processing waits for reconciled session data.

### 19.7 Schema evolution

Every payload has a schema version; local migrations are explicit and tested; the backend accepts supported versions and rejects unknown ones with actionable non-sensitive codes; catalog version is separate from telemetry schema version; old enum values are never silently reinterpreted.

### 19.8 Clock and timezone

Source timestamps in UTC; durations from monotonic/accumulated active time; event-local offset/timezone preserved for day/week analysis; impossible clock shifts flagged for data quality without rewriting raw client timestamps.

### 19.9 Deletion

Deletion stops normal sync, prioritizes the deletion request, prevents queued records from uploading after the server tombstone, purges local records per approved policy, and prevents any later retry from recreating deleted data. Local sensitive files use an approved iOS file-protection class and are excluded from backup unless privacy/legal review approves backup.

---

## 20. External protection-loss observations

### 20.1 Meaning

Heal observes protection state at discrete times; it does not know when an external change occurred. Use an event such as `external_protection_loss_detected`, where detection time means exactly that. Observations are canonical; detections are derived transitions (section 14.7).

### 20.2 Protection types

- Safari extension no longer enabled.
- Screen Time authorization no longer approved.
- System Website Filtering no longer enabled when historical product state expects it.

### 20.3 Detection fields

Store: detection timestamp; protection type; prior known state; most recent known healthy observation when available; last Safe Place session ID; last episode ID; last session end timestamp; installation/user; observation trigger and schema version.

### 20.4 Detection owner

**Recommendation**: one protection-health store coordinates current observations from `AuthorizationService`, `SafariExtensionService`/enablement model, `SystemWebFilteringService`, and `OnboardingProgress.systemWebFilteringDecision`. It persists last stable observations and emits one deduplicated loss detection per healthy-to-unhealthy transition; a later healthy observation closes recovery, and a new loss may emit another event. The authorization-predicate mismatch in section 3.9 must be resolved before reuse.

### 20.5 Known transient risk

The documented brief Screen Time `notDetermined` launch state can create a false loss if treated as final. The protection-observation milestone must define and test a stable-observation policy and must not mix a speculative fix for the underlying launch behavior into earlier product milestones.

### 20.6 Reporting

Reports display elapsed time from the last session end in readable hours/minutes/seconds. The database stores source timestamps, not only a formatted string or raw total seconds.

---

## 21. Future Safari blocked-page telemetry

A later extension milestone will distinguish: blocked page shown; Safe Place CTA pressed; Safe Place opened; repeated attempted access after intervention. These are separate from Safe Place entry measurement and are excluded from the first Safe Place measurement milestone.

Future design must: avoid arbitrary URLs and browsing history; use minimal event identity/correlation; respect extension networking and App Group constraints; apply consent, outbox, idempotency, and deletion rules; distinguish page-show time from app-open time; tolerate pages shown without a CTA tap.

Known issue: `docs/investigation-safari-first-navigation.md` records an intermittent first app-initiated navigation miss for the dedicated protection-test DNR rule; production-rule behavior was not established. This plan records the issue and adds no workaround.

---

## 22. TestFlight distribution

### 22.1 Confirmed distribution

Private TestFlight external testing; individually invited participants; approved-email backend allowlist; no public App Store launch; no separate invitation-code system unless later required. TestFlight invitation controls build access; the backend allowlist controls study account access; passing one never implies the other.

### 22.2 Internal testing before external

Required: developer/internal TestFlight builds; physical-device state-machine and offline tests; backend staging reconciliation; privacy/consent/deletion dry runs; upload duplicate/failure tests; content playback checks; Release-build verification that DEBUG controls are absent; Family Controls/Safari distribution entitlement validation.

### 22.3 External Beta App Review preparation

Prepare: accurate beta review notes and study purpose; login/test access instructions that respect allowlisting; privacy policy/support URLs; explanation of Family Controls and the broad Safari extension permission; consent and deletion paths; reviewed non-medical/emergency disclaimer wording; content/provider licensing and attribution review; a reproducible reviewer path that exposes no participant data.

### 22.4 Participant onboarding and study support

- Send the TestFlight invite and study instructions separately; confirm the auth email is allowlisted.
- Explain code-based sign-in, protection setup, Safe Place use, data collection, deletion, support, and build expiry.
- Provide support routes for expired builds, lost access, setup failure, and withdrawal; never ask participants to share verification codes or sensitive urge/free-text data through insecure channels.
- Track build expiration in App Store Connect; schedule replacement builds and reminders with margin; maintain a participant/build/support runbook; define removal/withdrawal handling before recruitment; verify current Apple TestFlight and entitlement requirements near distribution.

---

## 23. Dashboard-later plan

The dashboard is not a prerequisite for early Safe Place implementation.

Required order:

1. Finalize event and relational schema.
2. Implement Safe Place behavior and local measurement.
3. Implement auth, consent, remote ingestion, and offline reliability.
4. Verify end-to-end data quality through backend tables and CSV export.
5. Stabilize names and semantics.
6. Build the research dashboard.

The later dashboard covers: participant and installation activity; entries, sessions, and episodes; entry sources; rapid-return interval distributions; urge improvement and trend; session duration versus urge improvement; Breathe/feed/video time; content performance; prompt answer/Skip rates; exit feedback; external protection-loss observations; data-quality and upload-failure indicators. It queries raw entities/events or rebuildable derived views and never replaces source data with irreversible averages. Exact technology is open (27.6).

---

## 24. Implementation milestone order

### 24.1 Review policy (risk-based)

- Every implementation change requires a Change Report per `docs/AI-Change-Report-Protocol.md` (full report for milestone work, compact report for small isolated fixes), preceded by a Planned Change and reviewer confirmation.
- Simple, local, low-risk changes may use a **focused diff review**.
- A **full review bundle** is required when a change includes state or persistence, service ownership, routing or navigation, lifecycle/concurrency, cross-view interaction, backend/schema, privacy/security, or a significant architectural decision — matching `docs/AI-Coding-Guardrails.md`.
- Each milestone below states its **expected** review level, but the actual risk of the concrete diff remains authoritative in both directions: a small correction inside a milestone does not automatically require a full repository bundle, and an unexpectedly risky diff escalates.

Manual/device test detail lives in section 25; each milestone runs the matrix rows relevant to its scope plus a regression pass on adjacent flows. Proposed future filenames are recommendations, not existing repository symbols.

### 24.2 Milestones

#### MVP-0 — Contracts, decisions, and deterministic test foundation

- **Goal**: resolve blocking open semantics (section 27 items marked for MVP-0) and freeze version-1 domain/event/data contracts before product code.
- **Ownership/data flow**: define entry, session, episode, prompt, playback, and sync types plus a controllable clock for exact boundary tests.
- **Dependencies**: decisions on episode scope, 30-second clock, feed end behavior, initial content policy, exit completion methods (standalone and intercepted), preserved-prompt Exit behavior, Exit availability on Breathe, pre-auth/declined/underage/withdrawn behavior, canonical authorization predicates, Send Feedback transport, deletion negative paths, and local persistence technology (section 19.1 comparison).
- **Scope**: no product UI, live telemetry, or backend resources; a unit-test target, if approved, may touch `Heal.xcodeproj/project.pbxproj` with explicit approval.
- **Persistence/backend impact**: selects (does not yet productionize) local persistence; freezes the relational schema and ingestion contract on paper.
- **Expected review**: full bundle (architecture and persistence decisions).
- **Completion**: versioned contract and decision log approved; boundary tests specified; no unresolved semantic decision hidden in code.

#### MVP-1 — Product home and typed Safe Place entry routing

Recommended first source milestone; keep it small.

- **Goal**: minimal product home replacing the spike post-onboarding destination per the approved routing decision (section 6.2); typed research entry requests replacing the Boolean route; manual entry; `heal://safe-place?source=safariProtectionTest` routed into the non-study `functionalVerification` presentation context per section 7.3. No analytics/backend.
- **Likely files**: `Heal/ContentView.swift`, `Heal/HealApp.swift`, `Heal/SpikeAppState.swift` or an approved narrow routing owner, `Heal/SafePlaceView.swift`, proposed `HealHomeView.swift` and entry-domain type; Repair files only if required by the approved routing decision.
- **Ownership/data flow**: one root coordinator owns route priority; Safari production, shield, and manual actions create typed research entry requests; the functional-test callback opens Safe Place under `functionalVerification` without creating a research entry request; a read-only protection-health presentation owner feeds home status and routes to existing Repair without emitting telemetry.
- **Dependencies**: approved Repair-root decision (27.1); approved feedback/settings placeholder behavior (no dead buttons); approved authorization predicate per capability.
- **Scope**: out — research sessions, timing, urge prompts, auth, backend, playback analytics, Repair internals, handoff transport redesign; no research entity creation for `functionalVerification`.
- **Persistence/backend impact**: none beyond existing behavior; `SafariProtectionTestStore` pass marking remains.
- **Expected review**: full bundle (root routing, URL routing, cross-view ownership).
- **Completion**: one typed research-route source of truth; no duplicate pending Booleans; Safari, manual, and app-shield research sources verified on device; `functionalVerification` opens Safe Place, preserves pass marking, and creates no research provenance.

#### MVP-2 — Local persistence, clock, and domain-contract foundation

- **Goal**: implement the approved local store, migrations, controllable clock, installation-identity owner, and pure domain types from MVP-0, with deterministic tests and no product-flow change.
- **Ownership/data flow**: one serialized store owns entities/outbox identity; one installation owner creates `installation_id` before any durable study entity.
- **Dependencies**: MVP-0 technology and contract decisions.
- **Scope**: out — session behavior changes, UI, remote sync, auth.
- **Persistence/backend impact**: first local schema/migration (installation, outbox identity, checkpoint scaffolding); no backend.
- **Expected review**: full bundle (persistence foundation).
- **Completion**: store passes transaction, migration, recovery, and deletion tests; app behavior unchanged.

#### MVP-3 — Safe Place session lifecycle and active-time behavior

- **Goal**: session controller states/transitions (section 8), active-time recorder (section 9), repeated-entry attachment, initiating-entry cohort metadata, and background reconciliation using the MVP-2 foundation.
- **Ownership/data flow**: one session controller owns research states and IDs; one active-time recorder owns segments; `HealApp.swift` scene lifecycle feeds one serialized intake; `functionalVerification` presentations never enter this controller (section 7.3 / 8.2).
- **Dependencies**: MVP-1 typed research entries and `functionalVerification` routing; MVP-2 store/clock; approved pre-auth record rule.
- **Scope**: out — urge prompts, playback telemetry, remote ingestion, auth, handoff transport redesign; research recording for `functionalVerification`.
- **Persistence/backend impact**: in-memory-plus-checkpoint session state only to the extent MVP-4 has not yet landed; no backend.
- **Expected review**: full bundle (lifecycle, timing, concurrency).
- **Completion**: deterministic boundary tests pass for the 3-minute rules, repeated entries, and suspension; active durations exclude background/lock on device; initiating entry source is preserved for cohort assignment; `functionalVerification` produces no session.

#### MVP-4 — Durable session, checkpoint, and entity recording

- **Goal**: durably record sessions, entries, and active segments with the recovery checkpoint and outbox rows (upload still disabled), including force-quit reconciliation per section 8.4, while continuing to create zero research rows for `functionalVerification`.
- **Ownership/data flow**: session controller commits through the MVP-2 store; checkpoints reconcile on launch; research write path rejects `functionalVerification`.
- **Dependencies**: MVP-3 lifecycle.
- **Scope**: out — remote sync, prompts, playback records, app-shield transport redesign.
- **Persistence/backend impact**: session/entry/segment schema and checkpoint migration; no backend.
- **Expected review**: full bundle (persistence plus lifecycle interplay).
- **Completion**: raw segments reconcile to cached totals; corrupt checkpoints degrade to safe `unknown`; force-quit/relaunch claims no exact termination; multi-entry sessions retain every entry source; `functionalVerification` leaves the research store empty.

#### MVP-5 — Breathe urge prompt

- **Goal**: the optional Breathe `0–10` question with exact Continue answer/skip semantics (section 10).
- **Ownership/data flow**: view owns temporary selection presentation only; the controller finishes the prompt and transitions to feed; the store atomically records the prompt outcome and optional canonical measurement (14.7).
- **Dependencies**: MVP-4 recording.
- **Scope**: out — scheduled prompts, exit feedback, upload.
- **Persistence/backend impact**: prompt/measurement schema and migration; no backend.
- **Expected review**: full bundle (measurement semantics and persistence); UI-copy-only follow-ups may use focused diff review.
- **Completion**: prompt and measurement rows match section 10 exactly; no fake value for Skip; accessibility labels explain scale direction.

#### MVP-6 — Content catalog and feed-navigation contract

- **Goal**: stable internal content IDs, catalog version, source types, and a feed coordinator owning forward/back navigation and the intended-next-target contract, on the existing YouTube pager.
- **Ownership/data flow**: catalog owner and feed coordinator per section 13.2; `SafePlaceVideoCatalog.swift` and `SafePlaceView.swift` refactored behind them.
- **Dependencies**: MVP-0 ordering/end-of-catalog decision; MVP-4 store for content-view records.
- **Scope**: out — playback telemetry accuracy, hosted player, scheduled prompts.
- **Persistence/backend impact**: catalog version and content-view schema; no backend.
- **Expected review**: full bundle (navigation ownership and persistence).
- **Completion**: content views record stable IDs, source type, position, direction, and repeat ordinal; navigation semantics deterministic under tests.

#### MVP-7 — YouTube playback instrumentation

- **Goal**: instrument the current YouTube path sufficiently for the approved metrics — actual seconds played, completion, and segment end reasons — via an approved compliant approach (IFrame API or alternative), replacing `didFinish`-based assumptions.
- **Ownership/data flow**: player adapter emits callbacks; playback recorder persists raw segments; no telemetry writes from the player view.
- **Dependencies**: MVP-6 contract; the 27.2 YouTube instrumentation decision.
- **Scope**: out — Heal-hosted player, remote catalog management, scheduled prompts.
- **Persistence/backend impact**: playback-segment schema; no backend.
- **Expected review**: full bundle (provider behavior, player lifecycle, privacy, persistence).
- **Completion**: playback facts come from player callbacks; actual seconds versus feed-visible time reconcile on device; failure/background/exit close segments correctly.

#### MVP-8 — Scheduled feed prompt scheduler

- **Goal**: the four active-feed-time prompts with forward-transition interception, gesture semantics, and preserved backward state (section 11).
- **Ownership/data flow**: scheduler owned by the session controller or a subordinate single owner; feed coordinator provides the intended next target; the prompt view emits intents only.
- **Dependencies**: MVP-5 prompt model; MVP-6 navigation contract; resolved feed-end behavior.
- **Scope**: out — exit feedback, remote sync, dashboard.
- **Persistence/backend impact**: scheduled timing fields, completion methods, intended-next linkage, checkpoint state; no backend.
- **Expected review**: full bundle (timing, gestures, lifecycle, shared state).
- **Completion**: deterministic tests and raw records prove every schedule and gesture rule in sections 11 and 25.4; intended next content resumes correctly.

#### MVP-9 — Exit flow, local episode handling, and metric validation

- **Goal**: exit urge rules and detailed feedback (section 12), explicit completion returning to home, approved local episode behavior (canonical per installation or provisional for user-wide backend grouping), and local primary-metric reconciliation by initiating-entry cohort (section 7.3 / 15.1).
- **Ownership/data flow**: session controller owns exit state; the feedback view emits one answer/Skip; the store closes the session and writes final outbox entities atomically.
- **Dependencies**: confirmed 30-second clock, episode scope, and exit-control decisions; MVP-5/MVP-8 prompt semantics.
- **Scope**: out — remote dashboard, efficacy conclusions.
- **Persistence/backend impact**: exit feedback, final end fields, local episode relation/grouping version, reconciliation views/tests; no backend.
- **Expected review**: full bundle.
- **Completion**: full local experiment behavior is stable; raw records reproduce the primary Safari-cohort metric separately from the secondary manual cohort; local episode behavior is explicitly labeled canonical or provisional.

#### MVP-10 — Authentication, allowlist, installation registration, and consent

- **Goal**: approved-participant email plus numeric-code access (16.2), stable user identity, registration of the existing local installation identity, versioned consent with negative states, logout, and offline/expired-auth states.
- **Ownership/data flow**: auth owner supplies `user_id`; enrollment owner verifies the allowlist; consent owner gates upload; installation owner registers the already-generated `installation_id`.
- **Dependencies**: backend/provider and environment decision; privacy/legal-reviewed draft consent; approved declined/underage/withdrawal/pre-auth-linkage/logout/removal/re-consent behavior; MVP-9 local behavior.
- **Scope**: out — public signup, passwords, dashboard; client/dependency/project files only with explicit approval.
- **Persistence/backend impact**: local auth/session metadata in provider-approved secure storage; local consent/upload gate. Backend: the minimal reviewed identity/access subset (Auth configuration, allowlist, study profile/consent, installation registration, enforcement function/hook, narrow policies) in a non-production environment; the research telemetry schema remains MVP-11.
- **Expected review**: full bundle plus security/privacy review.
- **Completion**: identity model matches section 16; TestFlight and allowlist controls remain independent; consent versions are auditable; no behavioral upload before consent.

#### MVP-11 — Relational research schema, RLS, canonical episodes, and idempotent ingestion

- **Goal**: the reviewed research schema and a narrow ingestion contract for approved version-1 records on the selected backend (re-plan first if not Supabase). If episode scope is user-wide, backend reconciliation owns canonical episode assignment from raw sessions.
- **Ownership/data flow**: the database owns remote canonical rows and server receipt time; the ingestion RPC/function enforces auth, installation ownership, schema, idempotency, and mutation revisions.
- **Dependencies**: MVP-0 schema approval; MVP-10 auth/environment.
- **Scope**: out — production rollout, dashboard, Safari block-page reporting; migrations/functions/policies each separately approved.
- **Persistence/backend impact**: creates staging resources and RLS after explicit authorization; no local behavior change beyond contract fixtures.
- **Expected review**: full bundle plus security/privacy review.
- **Completion**: RLS, idempotency, and revision-ordering tests pass (including revision 3 before revision 2); no participant reads another participant's data; raw rows export to CSV correctly.

#### MVP-12 — Durable outbox, remote sync, and account deletion

- **Goal**: connect the local store to ingestion with offline retries, acknowledgements, duplicate prevention, token recovery, and the idempotent cross-device deletion flow (17.6, 19.9).
- **Ownership/data flow**: one sync coordinator, no view networking; a deletion coordinator stops sync and prevents resurrection.
- **Dependencies**: MVP-10 and MVP-11; reviewed deletion policy.
- **Scope**: out — dashboard, notifications.
- **Persistence/backend impact**: outbox statuses, retry metadata, receipts, deletion state, migrations; ingestion and deletion endpoints/functions.
- **Expected review**: full bundle plus security/privacy review.
- **Completion**: local and remote counts/IDs reconcile under failure injection (section 25.6); deletion completes, propagates across installations, and is auditable; local file protection and backup exclusion verified.

#### MVP-13 — Heal-hosted content player

- **Goal**: the Heal-hosted player, delivery, and offline/cache behavior as a separate milestone that **must complete before MVP-15 / external TestFlight readiness** under the current confirmed mixed-source plan (section 13.5).
- **Ownership/data flow**: a second player adapter behind the MVP-6 contract; the same playback recorder and schema.
- **Dependencies**: 27.2 hosting/player decisions; MVP-7 recorder.
- **Scope**: out — recommendations, remote catalog management beyond the approved delivery design. Becomes optional only after a later explicit product decision to run the first study with YouTube-only content.
- **Persistence/backend impact**: source-type coverage in existing schema; approved hosting/delivery resources only with explicit authorization.
- **Expected review**: full bundle (network/provider, player lifecycle, privacy, cost).
- **Completion**: hosted playback produces the same raw segment facts as YouTube per section 25.5; offline fallback verified; mixed-source library is ready for the study build.

#### MVP-14 — Protection-loss observations

- **Goal**: stable protection observations and derived loss-detection events per section 20, without claiming disablement time.
- **Ownership/data flow**: one observation owner reads existing technical sources and persists transitions; home status/Repair integration reuses it.
- **Dependencies**: MVP-12 sync; a reviewed stable-observation policy for the transient Screen Time state.
- **Scope**: out — fixing external disablement, tamper prevention, or the underlying `notDetermined` issue.
- **Persistence/backend impact**: last stable state, healthy timestamps, observation/loss records, dedupe/recovery fields; existing ingestion tables/policies.
- **Expected review**: full bundle.
- **Completion**: detection semantics explicit; no duplicate events under repeated refresh; raw source timestamps reconcile.

#### MVP-15 — Data-quality verification and private TestFlight readiness

- **Goal**: verify the entire study path, CSV data quality, Release privacy boundaries, support process, and external testing readiness (section 22), including mixed-source content.
- **Ownership/data flow**: no new product state owner; defects found are fixed as separately scoped changes at their own risk-based review level.
- **Dependencies**: MVP-1 through MVP-14, including completed MVP-13 under the current mixed-source plan; legal/privacy approval; distribution entitlements.
- **Scope**: out — dashboard, public launch.
- **Persistence/backend impact**: staging-to-production readiness and access review; no schema change unless a separately reviewed defect requires it.
- **Expected review**: full bundle for repository/configuration changes (Release distribution, privacy, entitlements); evidence report for study readiness.
- **Completion**: the full section 25 matrix passes in Release/internal TestFlight plus a limited external dry run; backend tables and CSV reconcile with device actions, including primary Safari cohort vs secondary manual cohort separation and zero research rows from `functionalVerification`; Beta App Review package and replacement-build plan ready.

#### MVP-16 — Research dashboard (later)

- **Goal**: the custom research dashboard after schema/event semantics are stable (section 23).
- **Ownership/data flow**: reads rebuildable raw/derived backend data; never becomes a source of truth.
- **Dependencies**: stable pilot data; approved dashboard technology.
- **Scope**: out — participant-facing urge history.
- **Persistence/backend impact**: optional rebuildable materialized views; read models and dashboard authorization.
- **Expected review**: full bundle plus privacy/access review.
- **Completion**: every displayed aggregate traces to raw data; denominators labeled; deletion propagates; access denial verified.

#### Later — app-shield durable handoff inbox (conditional)

- **Goal**: replace the single mutable App Group marker with an extension-safe durable inbox (one record per handoff UUID) and acknowledgement after local entry commit, per section 3.6.
- **Trigger**: only if app-shield entries are approved for study analysis or the overwrite risk becomes operationally material. Not part of the Safari-first critical path.
- **Dependencies**: MVP-4 durable recording; a reviewed App Group transport design.
- **Expected review**: full bundle (extension boundary, App Group persistence, lifecycle).
- **Completion**: two unconsumed handoffs retain two request IDs; acknowledgement only after durable commit; shield extension behavior otherwise unchanged.

#### Later — Safari blocked-page appearance reporting

- **Goal**: record each custom block-page appearance and its CTA/open correlation so exposure can be distinguished from entry (section 21), without arbitrary URL history.
- **Ownership/data flow**: the extension records minimal page-show/CTA correlation; an approved durable transfer path feeds ingestion; only the session controller creates Safe Place entries.
- **Dependencies**: stable MVP-12 ingestion/outbox; privacy/legal approval for exposure telemetry; a reviewed extension transport design.
- **Scope**: out — any workaround for the protection-test first-navigation miss; browsing history; server-backed blocking; Chrome parity.
- **Persistence/backend impact**: minimal extension-safe queue/inbox with correlation identity, retry/acknowledgement, and deletion support; new blocked-page/CTA events and reconciliation queries.
- **Expected review**: full bundle plus extension, privacy, security, and lifecycle review.
- **Completion**: raw records distinguish show, CTA, open, and entry without URL collection; counts reconcile; the dedicated test rule remains separately classified.

---

## 25. Acceptance criteria and device-test matrix

### 25.1 Automated acceptance

Deterministic tests for:

- source mapping and duplicate entry IDs; fixed Safari callbacks not falsely deduplicated without source identity;
- initiating-entry cohort assignment: `safari_block_page` → primary; `manual_in_app` → secondary; `app_shield` → non-primary; `unknown` → data-quality only / excluded from primary efficacy;
- multi-entry sessions retain every later entry/source while cohort membership follows the initiating entry only;
- `functionalVerification` (`safariProtectionTest`) opens Safe Place, marks the test, disables study prompts/feedback, and creates no research entry, session, episode, segment, urge, content-view, playback, exit-feedback, protection-observation, outbox, or research telemetry row;
- repeated entry in one session; explicit entry while suspended under/at the three-minute boundary;
- session return at `179.999`, `180.000`, and later seconds; explicit Exit then immediate re-entry;
- episode gap just under and exactly 600 seconds;
- active time excluding inactive/background;
- Breathe answer/skip; prompt due intervals and no fifth prompt; all prompt button/swipe outcomes; backward prompt preservation;
- Exit from a prompt preserved behind previous content; due-but-never-shown timeout versus shown-prompt timeout; visible-prompt inactivity closure;
- exit 30-second boundary after every completion method;
- primary metric eligibility and first/last answered selection within the Safari primary cohort; secondary manual cohort remains separable; app-shield and unknown initiating sessions excluded from primary efficacy;
- playback segment closure for both YouTube and Heal-hosted sources;
- outbox idempotency, ordering, migration, retry, and deletion; entity revision 3 before revision 2;
- auth/consent upload gate; RLS and cross-user denial.

### 25.2 Entry/routing matrix (physical iPhone)

- Icon launch, no handoff: home/gate, no entry.
- Manual home action: `manual_in_app` research entry; session assigned to the secondary cohort by initiating source.
- Production Safari block CTA: `safari_block_page` research entry; session assigned to the primary study cohort by initiating source.
- Functional Safari test CTA: `functionalVerification` presentation; Safe Place opens; test pass marking works; study prompts/feedback disabled; no research entities created; not assigned to any study cohort.
- App-shield action: `app_shield` provenance; session outside the primary study cohort unless separately approved.
- Malformed/unknown deep link: ignored, or `unknown` only under approved safe reconstruction; excluded from primary efficacy when it initiates a session.
- Second explicit route while active: another entry, same session; initiating cohort unchanged; later source preserved.
- Resume under three minutes: no automatic entry.
- Consumed shield marker: ordinary relaunch does not reopen Safe Place.

### 25.3 Session/lifecycle matrix

Active Breathe, feed, prompt, exit-urge, and feedback phases across: Home button/app switcher; lock/unlock; incoming interruption; return under three minutes; return exactly/over three minutes; force-quit in each phase; cold launch with durable checkpoint; explicit Exit and rapid re-entry; background timeout not restoring old exit feedback.

### 25.4 Prompt/navigation matrix

Each schedule boundary using active feed time; long pause/background not advancing the active timer; due prompt waiting through the current video; forward-transition interception; backward navigation before due, while due, and from a visible prompt; selected/unselected forward swipe; explicit Skip; Continue; intended next video resuming; finite-feed end behavior after its decision is approved.

### 25.5 Content/playback matrix

YouTube and Heal-hosted sources (both required for the currently planned external-study build): first play, repeat, backward view, forward skip, replay; full completion; buffering/failure/retry; no network; background/lock; app termination; actual playback seconds versus visible feed seconds; provider content removed/unavailable; catalog version update and bundled fallback; mixed-source feed containing both source types in one session.

### 25.6 Auth/privacy/sync matrix

Approved and unapproved email; wrong/expired/reused verification code; consent accept/version change/decline; underage, withdrawal, and re-consent paths; no sensitive upload before consent; online/offline first launch; offline enrolled intervention; auth expiration during an active session; reinstall and second device; logout/user-switching isolation; duplicate upload and out-of-order delivery; server rejection and retry; account deletion and queued-event suppression; lost deletion acknowledgement and cross-device tombstone propagation; participant removal; free-text access/logging review.

### 25.7 Protection matrix

Safari extension enabled/disabled/re-enabled; Screen Time approved/revoked/transient launch display; SWF historical Enabled with live enabled/cleared; SWF historical Skipped with live cleared; home status and Repair route per the approved routing decision; detection timestamp distinguished from disablement time; no speculative fix to the two documented known issues.

### 25.8 Distribution matrix

Debug versus Release control visibility; direct developer build; internal TestFlight; external Beta App Review build; normal and Private Browsing Safari; Safari and non-Safari default browser for the dedicated functional test; fresh install, upgrade, build replacement, build expiry handling; invite email different from a non-allowlisted auth attempt; Family Controls distribution entitlement and extension embedding.

### 25.9 Data reconciliation acceptance

For scripted/manual scenarios, reconcile: on-device entity/event IDs; outbox pending/acknowledged counts; backend rows and server receipt times; CSV export; derived primary metric restricted to the Safari primary cohort by initiating entry source; secondary manual-cohort metrics reported separately; unknown-initiated and app-shield-initiated sessions excluded from primary efficacy; raw duration segments; prompt denominators; deleted-user absence; zero duplicates after idempotent retries; zero research rows from `functionalVerification` callbacks; every later re-entry still present for multi-entry sessions.

---

## 26. Architectural risks

1. **`SpikeAppState` breadth** — adding auth, sessions, telemetry, and observation would create a monolith; split responsibilities without duplicating writable state.
2. **Root priority regression** — home, onboarding, Repair, auth/consent, and Safe Place interrupts can conflict; one coordinator defines and tests priority, and the Repair-root decision (27.1) must be explicit.
3. **Timing drift** — view timers or wall-clock subtraction would count background time; use one active-time owner and a controllable clock.
4. **Termination ambiguity** — iOS guarantees no exact termination callback; preserve checkpoints and detection semantics.
5. **Prompt/pager gesture conflict** — prompt insertion and backward preservation need a feed coordinator, not ad hoc cell state.
6. **YouTube measurement** — WebView load callbacks are not playback truth; never ship fabricated playback metrics.
7. **Mixed-player mismatch** — normalize only facts both players support; preserve provider-specific quality flags.
8. **Offline durability** — `UserDefaults`, fire-and-forget networking, or one mutable JSON blob risks loss/duplication; use transactional local commit plus idempotent ingestion.
9. **Sensitive data** — minimize fields, enforce consent/RLS/deletion, keep payloads out of logs.
10. **Identity confusion** — email, verification code, user ID, and installation ID have distinct roles; never use the code as an ID or duplicate email into event rows.
11. **Episode concurrency** — multi-device/offline sessions arrive out of order; preserve raw boundaries and version grouping.
12. **False protection-loss inference** — observation time is not disablement time; the transient Screen Time state exists; use reviewed stability logic.
13. **Provider/backend dependency** — Supabase and YouTube add availability/policy/cost risk; keep the intervention locally durable.
14. **Distribution entitlement** — development success does not prove TestFlight approval; validate Family Controls distribution early.
15. **Scope expansion** — dashboard, blocked-page reporting, notifications, personalization, and tamper resistance can derail the experiment; enforce milestone boundaries.
16. **Entry transport limits** — the shield handoff is one mutable slot and the Safari callback has no correlation ID; never claim exactly-once Safari delivery, and treat the shield inbox redesign as conditional later work.
17. **Out-of-order mutation** — unique event IDs stop duplicate retries but not stale snapshots; prefer immutable transitions or monotonic per-entity revisions.

---

## 27. Explicitly open decisions

Implementation stops at a decision boundary whenever the answer changes architecture, persistence, routing, lifecycle, behavior, privacy, or scope. Recommendations are labeled and are not approvals.

### 27.1 Product/research

- Exact feed content ordering, selection, repeat, and end-of-catalog behavior.
- Whether app-shield entries are ever included in study analysis (they remain outside the primary first-study cohort by confirmed decision; inclusion requires separate approval).
- Whether the first study may later switch to YouTube-only content (mixed-source is the current confirmed plan; MVP-13 is required until an explicit YouTube-only decision exists).
- Numerical efficacy/success threshold and minimum sample/eligible-session count.
- Whether Exit is available from Breathe and its pre-completed-prompt behavior.
- Whether the 30-second Exit interval uses active Safe Place time or wall time.
- Exact controls/completion methods on a standalone exit-urge prompt, and the completion method when Exit finishes an already-visible or preserved scheduled prompt.
- Episode ownership across a user's multiple installations versus per installation. (The 10-minute episode boundary itself is confirmed, not open.)
- Whether mandatory post-onboarding Repair presentation is replaced by home status with an explicit Repair route (section 6.2).
- Behavior when a participant is removed while local data remains.
- Send Feedback transport and support workflow.

Recommendations: versioned curated feed policy; active time for the 30-second interval; Continue plus distinct explicit Skip on a standalone exit prompt; restore a preserved prompt as the exit measurement; user-scoped backend episode grouping with raw sessions preserved; home status plus explicit Repair route; app-shield kept operational but analyzed separately; keep mixed-source content for the first external study unless product explicitly decides otherwise.

### 27.2 Content/player

- Exact YouTube instrumentation (IFrame API or compliant alternative).
- Heal-hosted storage/CDN, player, caching, and signed-URL strategy.
- Content metadata and curation workflow; offline fallback and cache size; provider failure/replacement policy.

Recommendation: run the focused technical milestones (MVP-7, MVP-13) before finalizing either player; never infer playback from page load.

### 27.3 Backend/auth

- Supabase project, regions, staging/production environment management, secrets, migrations, and ownership.
- Exact approved-email allowlist enforcement mechanism.
- Verification-code delivery/expiry parameters within the confirmed code-entry UX (the code-entry UX itself is confirmed, section 16.2).
- Token storage implementation.
- Behavior after explicit logout, auth expiry, allowlist removal, and user switching.
- Whether first-time Safe Place can run before authenticated consent; whether declined, underage, or withdrawn people retain an explicitly unmeasured local Safe Place; whether allowed pre-auth local records are later linked or purged.
- Canonical authorization predicates for Screen Time-dependent capabilities, including `.approvedWithDataAccess`.

Recommendation: separate staging and production environments, provider-managed identity, server-enforced allowlist, local intervention continuity for previously consented participants.

### 27.4 Local persistence/sync

- Exact local outbox/persistence technology.
- Episode provisional/canonical assignment implementation.
- Batch size, retry ceilings, retained diagnostic duration, background sync opportunities.
- Offline account deletion behavior; cross-device deletion acknowledgement and lost-ack retry; local file-protection class and backup exclusion.

Recommendation: the smallest database-backed platform option that passes transaction, migration, recovery, and deletion tests.

### 27.5 Privacy/legal

- Final consent, age, privacy, disclaimer, emergency, and deletion wording.
- Final retention policy after privacy/legal review.
- Whether operational/legal records must be retained after account deletion.
- Free-text limits and researcher access; study ethics/research review requirements.

### 27.6 Dashboard/operations/distribution

- Dashboard technology and hosting.
- Study support ownership and service levels; participant removal/withdrawal procedure.
- TestFlight replacement-build cadence; final Family Controls entitlement and Beta App Review requirements.

---

## 28. Post-MVP backlog

Explicitly out of the first product-validation MVP:

- Lockout Timer.
- Uninstall-attempt messaging.
- Tamper-proof guarantees.
- Account passwords.
- Social network or user-generated feed.
- Public App Store launch.
- Chrome CTA parity.
- Advanced personalization/recommendations.
- Notifications.
- Gamification and streaks.
- Personal urge-history UI.
- Custom dashboard before telemetry is stable.
- Server-backed protection enforcement.
- Full Safari blocked-page reporting in the first Safe Place milestone.
- App-shield durable handoff inbox redesign (conditional later milestone, section 24.2).
- App-shield inclusion in study analysis (requires separate approval).
- Advanced crisis escalation workflows unless separately defined and reviewed.
- Broad commercial subscriptions/monetization.

Known separate issues to retain without solving in the first product feature milestone:

1. The dedicated Safari protection-test DNR redirect can intermittently miss the first app-initiated navigation (`docs/investigation-safari-first-navigation.md`).
2. Screen Time authorization can briefly appear `notDetermined` on some launches before lifecycle refresh corrects it.

Any future work on these items requires its own contradiction check, scope, Change Report, risk-based review level, and device tests.
