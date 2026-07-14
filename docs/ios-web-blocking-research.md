# Heal / Safe Place — iOS Web Blocking and Intervention Research

**Status:** Living research record  
**Point in time:** 14 July 2026  
**Toolchain audited:** Xcode 26.6, iOS SDK 26.5, deployment target 26.5  
**Purpose:** Preserve validated knowledge, evidence tiers, product decisions, and open unknowns for Heal’s website-blocking and Safe Place intervention work so future development does not depend on a single chat or agent session.

> This document describes the state as of the date above. iOS behavior, Apple APIs, distribution entitlements, and regional limits may change in later releases. Any future update should record date, OS version, SDK version, and evidence type.

---

## 1. Document status and scope

This record covers:

- Existing Screen Time shield and App Group handoff architecture in Heal.
- Real-device website-shielding observations for Safari and Chrome (research-session narrative).
- Formal spike validation for **app** shielding (`docs/Spike-Validation-Report.md`).
- Adult `ActivityCategoryToken` investigation (picker + `FamilyActivityData`).
- Remaining candidates: `webContent.blockedByFilter` (`.auto` / `.specific`), Safari Web Extension, Control Center.

Out of scope for this document’s conclusions:

- Claiming that `.auto(...)` or `.specific(...)` already provide a Heal button (untested).
- Claiming Apple has no adult-content classifier (the `.auto` filter is separate from category tokens).
- Treating informal browser tests as equivalent to the formal Milestone J/K validation report.

---

## 2. Executive summary

### Proven on a physical device (website Stage 1 — research record)

As of 14 July 2026, the research session recorded that:

1. Shielding a site with `ManagedSettingsStore.shield.webDomains` using a `WebDomainToken` from `FamilyActivityPicker` can show Heal’s custom shield in Safari.
2. The shield primary button can run `ShieldActionExtension`, write an App Group handoff marker, open Heal via `.openParentalControlsApp`, and route into Safe Place.
3. After a clean retest (delete app, reboot iPhone, clean build/install, re-authorize, re-select domain, re-apply shield) on baseline `9876d7f`, the custom shield also appeared in Safari Private Browsing. Root cause of earlier inconsistency was **not** proven.
4. In Chrome, the same Screen Time website-shield approach showed a **generic** Apple shield, not Heal’s custom shield.
5. A diagnostic attempt did not yield usable callbacks or data sufficient to build a Heal button inside Chrome’s block UI.

**Evidence note:** These browser findings are documented in this research record. They are **not** covered by `docs/Spike-Validation-Report.md`, which validated **app** shielding only and explicitly listed web domains, categories, Chrome, and Private Browsing as not tested.

### Separately proven: app shield → Safe Place

`docs/Spike-Validation-Report.md` (13 July 2026) validates the app path: Family Controls authorization, one-app selection, default-store app shield, custom configuration, handoff, and Safe Place routing (Milestones A–K).

### Final conclusion on an Adult/Pornography category token

The following path is classified **NO-GO as of 14 July 2026 / Xcode 26.6 / iOS SDK 26.5** for obtaining a public Adult/Pornography `ActivityCategoryToken`:

```text
Adult/Pornography ActivityCategoryToken
→ store.shield.webDomainCategories
→ Heal custom shield
→ button
→ Safe Place
```

Reasons (not an implementation bug):

- Native `FamilyActivityPicker` was presented without Heal-side category filtering.
- Full `FamilyActivityData.activityCategories` was enumerated on a real device with data-access authorization.
- Exactly **12** system categories were returned; each reported a present token; none matched Adult / Pornography / Explicit / Sexual / Mature name terms.
- Apple’s adult-content **filter** (`.auto(...)`) is a different API and does not expose an `ActivityCategoryToken` for `webDomainCategories`.

### Remaining primary options

1. `webContent.blockedByFilter = .auto(...)` — Apple’s automatic adult-content filtering (**Requires device spike** for Heal UI/button).
2. `webContent.blockedByFilter = .specific(...)` — manually typed domains via `WebDomain(domain:)` (**Requires device spike** for Heal UI/button).
3. If filters block without a usable button/callback: Safari Web Extension with a Heal-controlled block page (**not implemented**).
4. Control Center control to open Safe Place — complementary, **deferred** until blocking paths are exhausted.

---

## 3. Product requirements

The product need is not only “prevent page load.” Two capabilities are required together:

### Requirement A — Active intervention

```text
Site is blocked
→ at least one clear action control is shown
→ tap opens Heal
→ Safe Place is presented immediately
```

The entire block surface need not be Heal-branded. A controllable action that opens Heal is sufficient for Requirement A.

### Requirement B — Broad coverage

One or both of:

1. Automatic adult-content blocking (classifier or equivalent).
2. Adding domains via a text field, without requiring the domain to already appear in `FamilyActivityPicker`.

### Decision principle

Blocking without a clear path into Safe Place is only a partial solution. Every spike must separately record:

- whether the site was blocked;
- which UI appeared;
- whether `ShieldConfigurationExtension` ran;
- whether `ShieldActionExtension` ran;
- whether a button appeared;
- whether the button opened Heal;
- whether Heal entered Safe Place directly.

---

## 4. Evidence model

| Tier | Meaning |
|---|---|
| **Apple documented** | Stated in official Apple documentation or the public Swift interface of the installed SDK. |
| **Local SDK audit** | Verified in the Xcode / iOS SDK installed on the development Mac. |
| **Real-device evidence** | Observed on a physical iPhone. |
| **Code inspection** | Derived from current Heal sources and/or Git diffs. |
| **Git diff inspection** | Derived from commit history / branch tips. |
| **Inference** | Plausible but unproven; must remain labeled. |
| **Requires device spike** | Cannot be decided from docs or code review alone. |
| **NO-GO (as of date/toolchain)** | Investigated enough to stop investing in this path for the stated point in time. |

---

## 5. Repository and baseline history

### Relevant commits

| Commit | Subject | Role |
|---|---|---|
| `9876d7f` | `feat: add website-triggered Safe Place feasibility Stage 1` | Selected product baseline for continued website work. |
| `ce26bb3` | `chore: add website shield callback diagnostics` | Diagnostics-only commit; not a Private Browsing functional fix. |

**Git state note (historical vs current):** As of 14 July 2026 during this rewrite, local `main` and `spike/adult-category-shield` both pointed at `9876d7f`. Branch tips and working trees can change; treat branch tables as historical research context unless re-verified.

### Baseline decision

Continue product development from `9876d7f`.

Diff `9876d7f..ce26bb3` (Git diff inspection) showed:

- Diagnostic logging and App Group diagnostic file writing.
- DEBUG export/clear UI affordances.
- App Group entitlement added to **HealShieldConfig** on that commit only (for log writing).
- Returned shield configuration content unchanged in purpose (supportive Heal shield).
- Button response remained website handoff then `.openParentalControlsApp`.
- No Private Browsing workaround, retry, reapply, cache invalidation, or architectural fix.

Therefore `ce26bb3` is retained only as a diagnostic backup tip:

```text
backup/private-browser-shield-callbacks-before-reset → ce26bb3
```

On current `main` / `9876d7f`, `HealShieldConfig/HealShieldConfig.entitlements` contains Family Controls only (no App Group). The App Group on ShieldConfig exists on the diagnostic commit, not on the product baseline.

### Relevant branches (as recorded 14 July 2026)

| Branch | Role |
|---|---|
| `main` | At `9876d7f` during this research window. |
| `backup/private-browser-shield-callbacks-before-reset` | Holds `ce26bb3`. |
| `spike/private-browser-shield-callbacks` | Exists at `9876d7f`; not intended for continued development. |
| `spike/control-center-safe-place` | Created from `main`; Control Center work deferred. |
| `spike/adult-category-shield` | Category-token spike; may contain uncommitted probe/research changes. |

### Adult-category spike working tree (research)

Uncommitted research artifacts on `spike/adult-category-shield` may include:

- `Heal/AdultCategoryShieldService.swift`
- `Heal/AdultCategoryShieldView.swift`
- `Heal/FamilyActivityCategoryTaxonomyProbe.swift`
- `Heal/Heal.entitlements` (`app-and-website-usage`)
- Temporary edits to `AppSelectionView` and shield extensions from the spike

Do not promote the probe into product without an explicit decision. `main` was not changed for this spike.

---

## 6. Existing architecture

**Evidence:** Code inspection.

### Targets

1. **Heal** — main app.
2. **HealShieldConfig** — `ShieldConfigurationExtension` (custom shield appearance).
3. **HealShieldAction** — `ShieldActionExtension` (button handling).

### App shield

- Default `ManagedSettingsStore` (`ShieldService`).
- Applies `store.shield.applications`.
- Primary action writes app handoff (`HandoffWriter.writePendingAppHandoff`) and returns `.openParentalControlsApp`.

### Website shield Stage 1

- Named store `websiteFeasibility` (`WebsiteShieldService.storeName`).
- Applies `store.shield.webDomains` with a picker-selected `WebDomainToken`.
- Website selection in the spike UI is session-only (`WebsiteFeasibilityView`); not persisted like the one-app selection (`SelectionPersistence`).

### Adult-category spike store (research only)

- Named store `adultCategoryShield` (`AdultCategoryShieldService`).
- Applies `store.shield.webDomainCategories = .specific([categoryToken])`.
- Does not replace the website Stage 1 store.

### Handoff

App Group:

```text
group.com.itamar.Heal
```

Schema (`HandoffStore` / `HandoffWriter`):

- `pendingSafePlaceLaunch`
- `createdAt`
- `triggerKind`
- `sessionId`

Supported `triggerKind` values for Safe Place routing (`SpikeAppState.isSupportedHandoffTriggerKind`):

- `app`
- `webDomain`

Markers older than **5 minutes** are ignored (`HandoffStore` validity window). Stale-marker behavior was not formally device-tested in `Spike-Validation-Report.md`.

Shield Action writes the marker, then returns:

```swift
.openParentalControlsApp
```

The main app evaluates the marker on launch/foreground and presents `SafePlaceView`, then consumes the marker.

### Shield Configuration

`ShieldConfigurationExtension` implements:

- `configuration(shielding application:)`
- `configuration(shielding application:in category:)`
- `configuration(shielding webDomain:)`
- `configuration(shielding webDomain:in category:)`

All return the same supportive Heal configuration. Subtitle copy still refers to “this **app**” even for web/category cases (copy inconsistency; not an architectural blocker).

### Category action-handler ambiguity

**Local SDK audit:** `ShieldActionDelegate` exposes separate handlers for:

- `application`
- `category`
- `webDomain`

There is **no** public overload:

```swift
handle(action:for webDomain:in category:...)
```

(Configuration **does** have `configuration(shielding webDomain:in category:)`.)

In the adult-category spike, the category action primary path was wired to website handoff because the named store only set `webDomainCategories`. That is acceptable for an isolated spike; it is **not** a general architecture if Heal later also uses `applicationCategories`.

---

## 7. Browser-specific device findings

### Safari — domain token shielding

**Real-device evidence (research record, 14 July 2026):**

```text
FamilyActivityPicker
→ WebDomainToken
→ store.shield.webDomains
→ Heal custom shield
→ primary button
→ Heal
→ Safe Place
```

Observed in normal Safari. **Code path** is fully wired. **Formal** Milestone report did not include website tests.

### Safari Private Browsing

Early observation: inconsistent behavior (generic shield on an older build vs custom shield after diagnostics work).

Clean retest on `9876d7f`:

- delete app;
- reboot iPhone;
- Clean Build Folder;
- build/install;
- re-authorize Family Controls;
- re-select domain;
- re-apply shield.

**Result:** custom Heal shield appeared in Private Browsing on `9876d7f`.

**Inference (not proven):** prior inconsistency was system state / extension load / selection state. Diagnostics commit `ce26bb3` did not contain a functional Private Browsing fix.

**Evidence tier:** informal real-device retest recorded here — not in `Spike-Validation-Report.md`.

### Chrome on iOS

**Real-device evidence (research record):** opening a blocked site in Chrome showed a **generic** Apple shield.

Not obtained:

- Heal custom shield;
- Heal button on the block screen;
- a reliable callback usable for Safe Place intervention inside Chrome’s UI.

**Temporary product decision:** prioritize Safari users. Network Extension, DNS Proxy, or notification-based Chrome work is deprioritized because, at best, it likely yields a separate notification rather than a button inside Chrome’s generic shield.

Chrome Incognito was listed as a future check in recommended spikes; it was **not** separately documented as completed in this research record.

---

## 8. Website token shielding (validated path for Safari)

```text
User selects a system-listed domain
→ WebDomainToken
→ store.shield.webDomains
→ custom shield
→ action callback
→ Heal / Safe Place
```

**Strengths**

- Custom shield + button path observed in Safari (research record).
- Observed in Safari Private Browsing after clean retest on `9876d7f`.

**Limits**

- Domain must appear in the picker.
- No public documented API converts an arbitrary domain string into a `WebDomainToken` for `shield.webDomains`.
- Apple documents a limit of up to 50 web domains in related Managed Settings web-filter policies; treat picker token counts as subject to Apple platform limits as documented for the relevant API.

---

## 9. Adult-category token investigation

### 9.1 Hypothesis

If Apple exposed Adult/Pornography as an `ActivityCategoryToken`, Heal could apply:

```swift
store.shield.webDomainCategories = .specific([adultCategoryToken])
```

Apple documents that category-based web-domain shielding uses the shield configuration and action extensions. That would have been the ideal wide-coverage + Heal-button path.

### 9.2 Initial spike — FamilyActivityPicker

Branch:

```text
spike/adult-category-shield
```

Implementation (code inspection):

- Presented native `FamilyActivityPicker`.
- Accepted exactly one category token.
- Rejected application tokens, web-domain tokens, and multiple categories.
- Applied via `store.shield.webDomainCategories = .specific([categoryToken])`.
- Reused supportive Heal shield and website handoff.

### 9.3 Picker result on device

**Real-device evidence:** top-level categories shown:

1. Social  
2. Games  
3. Entertainment  
4. Creativity  
5. Education  
6. Health & Fitness  
7. Information & Reading  
8. Productivity & Finance  
9. Shopping & Food  
10. Travel  
11. Utilities  
12. Other  

No Adult / Pornography / Explicit / Sexual / Mature category row was observed.

### 9.4 Implementation audit

Local code + SDK audit concluded:

- UI is Apple’s native picker, not a custom Heal list.
- Binding is a direct empty `FamilyActivitySelection`.
- No public picker parameter filters apps vs websites vs categories.
- Validation runs after selection and cannot hide picker rows.
- `includeEntireCategory` affects what selection includes, not which categories are listed (**Apple documented** / SDK).
- No alternate picker overload exposes a different category catalog.
- The same `ActivityCategoryToken` type is used for app and web category policies; the store property selects the effect.
- The spike applied tokens to `webDomainCategories`, not `applicationCategories`.

**Conclusion:** absence of Adult in the picker is not a Heal filtering bug.

### 9.5 Installed SDK audit (Xcode 26.6 / iOS SDK 26.5)

- `ActivityCategoryToken` is opaque (`Token<ActivityCategory>`).
- No public initializer from a name such as `"Adult"`.
- No public enum case for Adult / Pornography / Explicit / Sexual Content as a category.
- `ActivityCategory.localizedDisplayName` is available only after a category/token is obtained.
- No public API to import a token from Settings → Screen Time.
- No public bridge from `.auto(...)` to an `ActivityCategoryToken`.

### 9.6 FamilyActivityData — final public taxonomy probe

As of iOS 26.4+ (**Local SDK audit**):

```swift
FamilyActivityData.shared.activityCategories
```

Apple documents this as the set of **all possible** activity categories (each with `localizedDisplayName` and `token`).

Requirements (**Apple documented**):

- `AuthorizationStatus.approvedWithDataAccess`
- Entitlement: `com.apple.developer.family-controls.app-and-website-usage`
- **Customer** use limited to devices in the EU signed into an Apple Account with an EU country/region
- Development and testing may be performed in any region with an Apple-provided provisioning profile
- Outside the EU, customer installs do not achieve `approvedWithDataAccess`; `FamilyActivityData` access fails with `FamilyControlsError.unavailable`

Temporary probe displayed only display names and token presence; did not access installed apps, visited domains, or persist raw tokens.

### 9.7 Device enumeration result

**Real-device evidence (research session, 14 July 2026):** the probe returned the **same 12** category names listed in §9.3. Each row reported `token: present`.

Result message recorded:

```text
No adult-related ActivityCategory exists in
FamilyActivityData.activityCategories.
```

**Caveat:** the 12 names are preserved from the research session narrative. Raw device console output was not archived as a separate artifact in the repository.

### 9.8 Decision

**RESULT 1 — No adult category exists** (taxonomy enumeration).

**NO-GO (as of 14 July 2026 / Xcode 26.6 / iOS SDK 26.5):** there is no supported public path to obtain an Adult/Pornography `ActivityCategoryToken` and apply it to `webDomainCategories` on the tested device/toolchain.

This does **not** mean Apple lacks an adult-content classifier. See §10.

### 9.9 Why `Other` is not a substitute

`Other` is a real category token and a broad catch-all. Selecting it for `webDomainCategories` would shield all websites Apple classifies under Other, including large amounts of non-adult content.

Therefore:

- it is not a hidden Adult category;
- membership cannot be privately inspected from the opaque token alone;
- it causes uncontrolled overblocking;
- it does not meet the product requirement.

### 9.10 Distinction: adult filter ≠ adult category token

Apple provides:

```swift
store.webContent.blockedByFilter = .auto(...)
```

This is `WebContentSettings.FilterPolicy` (“the system blocks adult content”), **not** an `ActivityCategoryToken`. There is no public API converting that classifier into a token for `webDomainCategories`.

---

## 10. Automatic adult-content filtering — `.auto(...)`

**Local SDK audit** (`ManagedSettings.WebContentSettings.FilterPolicy`):

```swift
case none
case specific(Set<WebDomain>)
case auto(Set<WebDomain> = [], except: Set<WebDomain> = [])
case all(except: Set<WebDomain> = [])
```

Primary candidate:

```swift
store.webContent.blockedByFilter = .auto(
    additionallyBlockedDomains,
    except: allowedDomains
)
```

### Apple documented

- The system blocks adult content (`.auto`).
- Additional domains may be blocked; exceptions may be allowed.
- Up to 50 blocked domains and up to 50 exceptions for the filter APIs that accept domain sets.
- Setting any filter policy other than `.none` **disables Safari Private Browsing** while the policy is active (`blockedByFilter` discussion).

### Not documented / not proven for Heal

No guarantee that `.auto`:

- shows Heal’s custom shield;
- invokes `ShieldConfigurationExtension`;
- invokes `ShieldActionExtension`;
- shows a button that can open Safe Place.

### Current assessment

**Inference:** likely a separate web-content filter with generic restriction UI, because Apple separates `store.shield.*` from `store.webContent.blockedByFilter`.

**Requires device spike** before GO / PARTIAL / NO-GO for Requirement A.

Heal has **not** implemented `.auto(...)` as of this document date.

---

## 11. Manual domain filtering — `.specific(...)` and `WebDomain(domain:)`

Apple allows:

```swift
let domain = WebDomain(domain: "example.com")
store.webContent.blockedByFilter = .specific([domain])
```

### Documented

- `WebDomain` can be created from a string (**SDK** + Apple docs).
- `.specific` blocks provided domains.
- Up to 50 domains.
- Non-`.none` `blockedByFilter` disables Safari Private Browsing while active.

### Unknown (Requires device spike)

- Heal custom shield vs generic restriction page.
- Whether shield configuration/action extensions run.
- Whether any button can open Heal / Safe Place.
- Subdomain / `www` / scheme / port matching in practice.
- Chrome and Chrome Incognito behavior.

### Manual `WebDomain` vs `WebDomainToken`

There is no public initializer such as:

```swift
WebDomainToken(domain: "example.com")
```

`WebDomainToken` is a privacy-preserving token (`Token` exposes `init(from: Decoder)` only in the public interface). `WebDomain` has an optional `token` property, but Apple does not document that a manually constructed `WebDomain` yields a usable token for `store.shield.webDomains`.

Trying that conversion is a **low-probability experiment**, not an approved product path, until proven.

**Do not conflate:**

| Type / API | Role |
|---|---|
| `WebDomain` | Domain value used by web-content filter policies |
| `WebDomainToken` | Opaque token used by `shield.webDomains` |
| `store.webContent.blockedByFilter` | Web content filter (`.auto` / `.specific` / `.all`) |
| `store.shield.webDomains` | Shield specific domain tokens |
| `store.shield.webDomainCategories` | Shield by category tokens |

---

## 12. Chrome and third-party browsers

Desired flow:

```text
Chrome opens blocked domain
→ button appears
→ user taps
→ Heal opens Safe Place
```

Observed:

- Generic shield.
- No proven control of its text or button.
- Diagnostic attempt did not provide a reliable callback/data path.

Paths considered and deprioritized:

1. `NEFilterManager` / content filter  
2. DNS Proxy  
3. Newer URL filter APIs  
4. Packet Tunnel / local VPN  
5. Notification as a button substitute  

**Decision:** these are not expected to inject a button into Chrome’s generic shield. At best they may detect an event and post a notification. Chrome research is paused while the product prefers an in-block-screen action over notification-only UX.

---

## 13. Safari Web Extension candidate

If `.auto` / `.specific` block without a button/callback, a Safari Web Extension remains a research candidate.

Possible flow:

```text
Safari request
→ extension matches blocked domain
→ redirect to Heal-controlled block page
→ “Open Safe Place” control
→ Universal Link / deep link
→ Heal / Safe Place
```

**Potential strengths:** full control of block page and button; typed domains; own adult-domain list or classification service; Safari-focused.

**Limits / unknowns:**

- New extension target and platform surface (**not implemented**).
- User must enable the extension and grant site permissions.
- Private Browsing needs appropriate extension permission.
- No bridge from Apple’s `.auto` classifier into the extension; Heal would need its own dataset/service.
- Redirect stability and App Review expectations on current iOS **Require device spike / implementation testing**.

**Status:** future candidate only — not proven architecture.

---

## 14. Control Center candidate (deferred)

Apple supports system controls via WidgetKit and App Intents (“Creating controls to perform actions across the system”).

Possible flow:

```text
Open Control Center
→ tap Heal / Safe Place control
→ App Intent launches Heal
→ route directly to Safe Place
```

May also be placeable on Lock Screen / Action Button depending on system capabilities and user configuration. The user must add the control manually.

This is **not** a blocking mechanism. It is an emergency entry path when a generic block UI has no Heal button.

Branch recorded:

```text
spike/control-center-safe-place
```

**Status:** no Heal Control Center implementation in the codebase as of this rewrite; deferred until `.auto` / `.specific` spikes are completed. Exact intent type (`OpenIntent` vs other App Intent patterns) should be confirmed against the installed SDK when that spike starts.

App Group is already used for shield handoff; a Control Center launch may not require a new App Group solely to open Safe Place, but any shared state should reuse existing patterns if needed (**Requires implementation design**).

---

## 15. Capability comparison matrix

| Mechanism | Auto adult block | Typed domain | Safari | Safari Private | Chrome | Heal custom shield | Action callback | Open Safe Place | Status |
|---|---:|---:|---|---|---|---|---|---|---|
| `shield.webDomains` + `WebDomainToken` | No | No (picker only) | Yes (research) | Observed after clean retest | Generic shield | Yes in Safari (research) | Yes in Safari (research) | Yes in Safari (research) | **Validated (Safari research record)** |
| `shield.webDomainCategories` + Adult token | Would have | No | In principle | Needs token | N/A | In principle | In principle | In principle | **NO-GO: no Adult token (14 Jul 2026)** |
| `blockedByFilter = .specific(...)` | No | Yes | Expected to block | Private disabled (documented) | Unknown | Unknown | Unknown | Unknown | **Next device spike** |
| `blockedByFilter = .auto(...)` | Yes | Optional add-on | Expected to block | Private disabled (documented) | Unknown | Unknown | Unknown | Unknown | **Next device spike** |
| Safari Web Extension | With own list/classifier | Yes | In principle | Needs extension Private permission | No | Heal-controlled page | Page button | Via link/routing | **Fallback research** |
| Network Extension / DNS Proxy | With own classifier | Yes | Broad | Broad | Maybe | Not inside Chrome shield | Notification at best | Notification→Heal possible | **Deprioritized** |
| Control Center control | Does not block | Does not block | Anywhere | Anywhere | Anywhere | N/A | System control | Yes (in principle) | **Deferred complement** |
| App `shield.applications` | N/A | N/A | N/A | N/A | N/A | Yes | Yes | Yes | **Validated (Spike-Validation-Report)** |

---

## 16. Rejected or deferred approaches

| Approach | Classification | Reason |
|---|---|---|
| Adult `ActivityCategoryToken` → `webDomainCategories` | **NO-GO (14 Jul 2026)** | Picker + full `activityCategories` enumeration: 12 categories, no adult-related name |
| Selecting `Other` as adult substitute | Rejected | Uncontrolled overblocking |
| Promoting `ce26bb3` as product baseline | Rejected | Diagnostics only |
| Chrome Network Extension / DNS / notification-first | Deferred / deprioritized | Unlikely to put a button inside Chrome’s generic shield |
| Control Center | Deferred complement | Does not solve blocking; useful after filter spikes |
| Safari Web Extension | Fallback research | Only if filters lack Requirement A |
| Hard-coding / decoding opaque tokens | Rejected | Private/unsupported; App Review risk |

---

## 17. Open questions and required device spikes

1. Does `.auto` show Heal custom shield or a generic restriction page?  
2. Does `.auto` invoke Shield Configuration / Action extensions?  
3. Does `.specific(WebDomain)` invoke those extensions?  
4. Does either present a usable button?  
5. Can either open Heal directly into Safe Place?  
6. `.auto` behavior in Chrome and Chrome Incognito.  
7. `.specific` behavior in Chrome and Chrome Incognito.  
8. Matching rules for `www`, subdomains, schemes, ports under `.specific`.  
9. Real-world coverage quality of Apple’s adult-content classifier.  
10. False positives / false negatives of `.auto`.  
11. Whether `WebDomain(domain:).token` is ever usable for `shield.webDomains` (low probability).  
12. If filters lack a button: Safari Web Extension redirect feasibility and App Review path.  
13. Production entitlement / App Review requirements for any chosen solution.  
14. Production-region impact of `FamilyActivityData` EU limits (relevant if any future feature depends on data access).

---

## 18. Recommended research sequence

### Suggested next branch

```text
spike/web-content-filter-behavior
```

Create from `main @ 9876d7f` after preserving findings from `spike/adult-category-shield`.

### Spike goal

On a physical device, test each state separately:

```swift
.auto([], except: [])
```

```swift
.specific([WebDomain(domain: "example.com")])
```

```swift
.auto([WebDomain(domain: "example.com")], except: [])
```

### For each state, record

1. Site blocked: yes/no  
2. UI: Heal custom / Apple generic / none  
3. `ShieldConfigurationExtension` called: yes/no/unknown  
4. `ShieldActionExtension` called: yes/no/unknown  
5. Button present: yes/no  
6. Button opens Heal: yes/no  
7. Direct Safe Place routing: yes/no  
8. Safari Private Browsing impact  
9. Whether clearing the filter restores Private Browsing  
10. Chrome and Chrome Incognito  
11. Adult-site sample(s) for `.auto`, explicit test domain for `.specific`, and one unrelated site for overblocking  

### Success criteria for product fitness

```text
Broad adult block and/or typed domain
+
Reliable button or callback
+
Safe Place open
```

If blocking works without a button, record it as **partial** capability and evaluate Safari Web Extension and/or Control Center as complements.

---

## 19. Chronological research log and product decisions

| Date | Decision / finding | Rationale / evidence |
|---|---|---|
| July 2026 | Baseline = `9876d7f`, not `ce26bb3` | Diagnostics-only diff; no functional Private Browsing fix |
| July 2026 | Prioritize Safari over Chrome | Custom shield + button observed in Safari; generic shield in Chrome |
| 13 July 2026 | App shield path validated (Milestones A–K) | `docs/Spike-Validation-Report.md` |
| 14 July 2026 | NO-GO Adult category token | Picker + `FamilyActivityData.activityCategories` → 12 categories, no adult-related name |
| 14 July 2026 | Do not use `Other` as substitute | Broad overblocking |
| 14 July 2026 | Next: `.auto` and `.specific` before Safari Extension | Smaller built-in API surface; UI/callback unknown |
| 14 July 2026 | Defer Control Center | Complements blocking; does not replace it |
| 14 July 2026 | Pause Chrome Network Extension / notification research | Unlikely to satisfy in-shield button requirement |

---

## 20. Source and evidence references

### Project artifacts

- `docs/Spike-Validation-Report.md` — formal app-shield validation (web domains not tested).  
- `Heal/WebsiteShieldService.swift` — named store `websiteFeasibility`, `shield.webDomains`.  
- `Heal/ShieldService.swift` — default store, `shield.applications`.  
- `Heal/HandoffStore.swift`, `HealShieldAction/HandoffWriter.swift` — App Group schema.  
- `HealShieldConfig/ShieldConfigurationExtension.swift`, `HealShieldAction/ShieldActionExtension.swift`.  
- Adult-category spike sources (may be uncommitted): `AdultCategoryShieldService.swift`, `AdultCategoryShieldView.swift`, `FamilyActivityCategoryTaxonomyProbe.swift`.

### Git

- `9876d7f` — website Stage 1 baseline.  
- `ce26bb3` — website shield callback diagnostics.  
- `backup/private-browser-shield-callbacks-before-reset` → `ce26bb3`.

### Installed SDK (Xcode 26.6 / iOS SDK 26.5)

- `ManagedSettings` Swift interface — `ShieldSettings`, `WebContentSettings.FilterPolicy`, `WebDomain`, `Token`.  
- `FamilyControls` Swift interface — `FamilyActivityPicker`, `FamilyActivitySelection`, `FamilyActivityData`, `AuthorizationStatus.approvedWithDataAccess`.

### Official Apple documentation (titles)

- FamilyActivityPicker  
- FamilyActivityData / activityCategories  
- AuthorizationStatus.approvedWithDataAccess  
- ShieldSettings (`webDomains`, `webDomainCategories`)  
- WebContentSettings / FilterPolicy / `blockedByFilter` / `.auto` / `.specific`  
- WebDomain.init(domain:)  
- WebDomainToken  
- ShieldActionDelegate handle methods  
- WidgetKit: Creating controls to perform actions across the system  
- Entitlement: Family Controls App and Website Usage (`com.apple.developer.family-controls.app-and-website-usage`)

---

## 21. Template for future findings

```markdown
### [YYYY-MM-DD] Test name

**Branch / Commit:**  
**Xcode / SDK / iOS:**  
**Device and browser:**  
**Mechanism tested:**  

**Code changes:**
- ...

**Test steps:**
1. ...

**Observed result:**
- Block: yes/no
- UI: Heal custom / Apple generic / none
- ShieldConfiguration callback: yes/no/unknown
- ShieldAction callback: yes/no/unknown
- Button: yes/no
- Open Heal: yes/no
- Safe Place routing: yes/no
- Private Browsing impact: ...
- Chrome impact: ...

**Evidence tier:** Apple documented / local SDK / real device / inference

**Conclusion:** GO / PARTIAL / NO-GO / requires another spike

**Git decision:** commit / discard / preserve diagnostic branch
```

---

## 22. Point-in-time conclusion (14 July 2026)

For **website** intervention with a custom Heal shield and Safe Place button, the only end-to-end path recorded as working in Safari is picker-selected `WebDomainToken` shielding via `store.shield.webDomains`.

Separately, the **app** shield path is formally validated in `docs/Spike-Validation-Report.md`.

As of Xcode 26.6 and iOS SDK 26.5 on the tested device, Family Controls does **not** expose a public Adult/Pornography `ActivityCategoryToken` (picker inspection + full `FamilyActivityData.activityCategories` enumeration of 12 categories). That path is **NO-GO** for category-token adult website shielding. Apple’s `.auto(...)` adult-content filter remains a distinct API and is **untested** for Heal’s button requirement.

Next research must decide whether `.auto(...)` and/or `.specific(...)` provide not only blocking but also a button or callback into Safe Place. If not, the most plausible Safari-focused fallback is a Safari Web Extension with a Heal-controlled block page, while Control Center remains a complementary non-blocking entry path.
