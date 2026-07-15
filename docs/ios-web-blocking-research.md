# Heal / Safe Place — iOS Web Blocking and Intervention Research

**Status:** Living research record
**Point in time:** 15 July 2026
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
- Completed device spike for `webContent.blockedByFilter` (`.auto` / `.specific`) and typed-`WebDomain.token` bridge (**AUTO-2** / **SPECIFIC-2** / **TOKEN-3**).
- Safari Web Extension block-page path: device-validated as **SAFARI-EXT-1** (14 July 2026). Control Center remains a deferred complement.
- Safari Web Extension + Managed Settings `.specific(...)` coexistence: device-validated as **COEXIST-SPECIFIC-1** (15 July 2026).
- Safari Web Extension + Managed Settings `.auto(...)` with an explicitly supplied domain: device-validated as **COEXIST-AUTO-1** (15 July 2026). Apple classifier-selected domain coexistence remains **unproven** (Stage 2B).

Out of scope for this document’s conclusions:

- Claiming that `.auto(...)` or `.specific(...)` provide a Heal button (device-tested: they do not).
- Claiming Apple has no adult-content classifier (the `.auto` filter is separate from category tokens and can block).
- Claiming Family Controls as a whole is a NO-GO (app shielding and token-based website shielding remain separate validated/researched mechanisms).
- Treating informal browser tests as equivalent to the formal Milestone J/K validation report.
- Claiming Chrome Incognito was separately verified for `blockedByFilter` (not recorded in this spike).

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

### Real-device `blockedByFilter` spike (14 July 2026)

On a physical iPhone, branch `spike/web-content-filter-behavior` (baseline `main` @ `48ef0f1`), Xcode 26.6 / iOS SDK 26.5:

| Mode | Classification | Blocking | Intervention (Requirement A) |
|---|---|---|---|
| `.auto(...)` | **AUTO-2 — Blocking only** | Tested adult site blocked; unrelated normal site not blocked | Generic `Website Not Allowed`; **no Heal button**; no route to Heal / Safe Place |
| `.specific(...)` | **SPECIFIC-2 — Blocking only** | Manually entered domain blocked; tested subdomain also blocked; unrelated site available | Same generic page; **no Heal button**; no route to Heal / Safe Place |
| `WebDomain(domain:).token` | **TOKEN-3 — No public usable token** | N/A | Public optional token was `nil` on device; no typed-domain → `WebDomainToken` → custom Shield bridge |

**Real-device evidence (both `.auto` and `.specific`):** Chrome showed the same generic blocking behavior. Safari Private Browsing **remained available** while each filter was active (see §10 / §11 for the documented-vs-observed discrepancy). Broader adult-classifier coverage and full hostname matching rules are **not** proven by these single-sample tests.

**NO-GO as of 14 July 2026 / Xcode 26.6 / iOS SDK 26.5** for adding a Heal button inside the `blockedByFilter` / `Website Not Allowed` experience. This is **not** a NO-GO for Family Controls as a whole.

### Remaining primary options

1. Safari Web Extension with a Heal-controlled block page and explicit “Open Safe Place” control — **SAFARI-EXT-1 (14 July 2026)** for the isolated `example.com` domain-family spike.
2. Hybrid: Safari Web Extension for Safari intervention UI; `.specific(...)` / `.auto(...)` as **blocking-only** fallback for Chrome and other browsers — **COEXIST-SPECIFIC-1** and **COEXIST-AUTO-1** (15 July 2026) for explicitly supplied `example.com` on the tested device (Safari extension won execution in normal and Private Safari; Managed Settings showed Apple generic page in Chrome). Apple classifier-selected domain coexistence and production-scale adult coverage remain **unproven** (Stage 2B).
3. Control Center control to open Safe Place — complementary non-blocking entry, **deferred**.
4. Picker-selected `WebDomainToken` → `shield.webDomains` — remains a recorded Safari path with custom Heal shield + Safe Place button (does not satisfy typed-domain or automatic adult coverage alone).

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

### Installed SDK inspection

`WebContentSettings` exposes only `blockedByFilter: FilterPolicy?`. No public UI customization, button configuration, action delegate, blocked-domain callback, or notification hook is present on this setting. `ManagedSettingsUI` / `ShieldActionDelegate` overloads correspond to Shield APIs, not to the generic filter page.

### Real-device evidence (14 July 2026)

Classification: **AUTO-2 — Blocking only**.

- A tested adult website was blocked.
- A clearly unrelated normal website was not blocked.
- Broader adult-site classification coverage is **not** proven by this single tested adult site.
- Visible UI was Apple’s generic **`Website Not Allowed`**.
- **No Heal button** was visible.
- No route from the blocked page to Heal or Safe Place was available.
- Chrome showed the same generic blocking behavior (Chrome Incognito was **not** separately recorded for this spike).
- Safari Private Browsing **remained available** while `.auto` was active.

**Documented vs observed (Private Browsing):** Apple documentation states that any filter policy other than `.none` disables Safari Private Browsing. On the tested device (14 July 2026), Private Browsing remained available under `.auto`. Preserve both statements: the documented claim is not deleted; the device result is a point-in-time observation requiring cautious interpretation (OS version, region, or other system state may matter).

**Proven finding for Requirement A:** blocking succeeded for the tested adult site; intervention failed (no visible actionable Heal button). This report does **not** claim Shield Configuration/Action callbacks were absent unless Console evidence was conclusively captured; the proven UI finding is no Heal button.

### Current assessment

**NO-GO as of 14 July 2026 / Xcode 26.6 / iOS SDK 26.5** for satisfying Requirement A via `.auto` / `Website Not Allowed`.

Blocking success ≠ intervention-flow success. `.auto` remains useful only as **blocking-only** coverage (for example Chrome fallback in a hybrid architecture).

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

### Real-device evidence (14 July 2026)

Classification: **SPECIFIC-2 — Blocking only**.

- A manually entered domain was blocked.
- A tested subdomain was also blocked.
- A clearly unrelated website remained available.
- Do **not** generalize the subdomain observation into a complete specification for all hostname, `www`, public-suffix, or IDN cases.
- Visible UI was Apple’s generic **`Website Not Allowed`**.
- **No Heal button** was visible.
- No route from the blocked page to Heal or Safe Place was available.
- Chrome showed the same generic blocking behavior (Chrome Incognito was **not** separately recorded for this spike).
- Safari Private Browsing **remained available** while `.specific` was active.

**Documented vs observed (Private Browsing):** same discrepancy as §10 — documentation says Private Browsing is disabled for non-`.none` policies; the tested device retained Private Browsing under `.specific`. Keep both; interpret cautiously.

**Proven finding for Requirement A:** typed-domain blocking succeeded for the tested host/subdomain sample; intervention failed (no visible actionable Heal button).

### Manual `WebDomain` vs `WebDomainToken`

There is no public initializer such as:

```swift
WebDomainToken(domain: "example.com")
```

`WebDomainToken` is a privacy-preserving token (`Token` exposes `init(from: Decoder)` only in the public interface). **Installed SDK inspection:** `WebDomain` exposes `public let token: WebDomainToken?`.

**Real-device evidence (14 July 2026):** for a manually created `WebDomain(domain: ...)`, the public optional `token` was **`nil`**. Classification: **TOKEN-3 — No public usable token**. No supported typed-domain → `WebDomainToken` → `store.shield.webDomains` custom Heal Shield path was available.

### Current assessment

**NO-GO as of 14 July 2026 / Xcode 26.6 / iOS SDK 26.5** for satisfying Requirement A via `.specific` / `Website Not Allowed`. Typed-domain **blocking** works; Heal intervention on that page does not.

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

### Token-based website shield (`shield.webDomains`) — prior research

Observed:

- Generic shield.
- No proven control of its text or button.
- Diagnostic attempt did not provide a reliable callback/data path.

### `blockedByFilter` — Real-device evidence (14 July 2026)

For both `.auto` and `.specific`, Chrome showed the same generic **`Website Not Allowed`** blocking behavior as Safari, with **no Heal button** and no route into Heal / Safe Place. Chrome Incognito was **not** separately recorded for this spike.

Paths considered and deprioritized for putting a Heal button *inside* Chrome’s block UI:

1. `NEFilterManager` / content filter
2. DNS Proxy
3. Newer URL filter APIs
4. Packet Tunnel / local VPN
5. Notification as a button substitute

**Decision:** these are not expected to inject a button into Chrome’s generic shield/filter page. At best they may detect an event and post a notification. For Chrome, the realistic near-term outcome remains **blocking-only** via `.auto` / `.specific` (AUTO-2 / SPECIFIC-2), while Safari intervention UI is pursued separately (Safari Web Extension candidate).

---

## 13. Safari Web Extension candidate

After the `blockedByFilter` spike classified **AUTO-2** / **SPECIFIC-2** / **TOKEN-3**, a Safari Web Extension was the next supported public-API candidate for a Heal-controlled block page with a visible button in Safari.

### 13.1 Device validation — 14 July 2026 (**SAFARI-EXT-1**)

**Test environment**

| Field | Value |
|---|---|
| Branch | `spike/safari-web-extension-block-page` |
| Baseline | `main` / `github/master` @ `72a2f3e` |
| Xcode | 26.6 |
| iOS SDK | 26.5 |
| Device | Physical iPhone |
| Date | 14 July 2026 |
| Managed Settings website filters | Not enabled for this path |

**Architecture tested**

```text
Safari main-frame navigation to the example.com domain family
→ static Manifest V3 declarativeNetRequest rule (main_frame, urlFilter ||example.com^)
→ redirect to extension-bundled blocked.html
→ visible “Open Safe Place” button (heal://safe-place)
→ explicit user tap
→ iOS confirmation: Open this page in “Heal”?
→ Heal
→ existing pendingSafePlaceEntry / SafePlaceView presentation
```

Permissions used: `declarativeNetRequestWithHostAccess`; host access limited to the `example.com` domain family (`*://example.com/*`, `*://*.example.com/*`). Exactly one static rule. No dynamic/session rules. No adult-domain list. No Managed Settings `.auto` / `.specific` / website shield in this path. Exact-host-only matching is **not** a product requirement for this spike; covering the registered domain and its subdomains is the intended test scope.

**Classification: SAFARI-EXT-1 — Full intervention path**

The required iOS confirmation before opening Heal is an expected system-controlled UX step and does **not** invalidate the classification. App opening is **not** silent or automatic.

**Validated test scope**

- `example.com` domain family (apex + subdomains via the static rule).
- Apex `https://example.com` redirect observed.
- Tested subdomain `https://www.example.com` also redirected (not a claim that every possible subdomain was tested).
- Unrelated websites unaffected.

**Normal Safari**

- `https://example.com` redirected to Heal-controlled `blocked.html`.
- `https://www.example.com` also redirected to the Heal-controlled page.
- Apple’s generic `Website Not Allowed` page did **not** appear.
- `Open Safe Place` was visible.
- Tap showed `Open this page in “Heal”?`; after approval, Heal opened into Safe Place with no extra setup screen.
- Unrelated websites were unaffected.

**Extension disabled**

- Disabling the extension restored normal access to `example.com`.

**Safari Private Browsing**

- Extension was enabled separately for Private Browsing.
- Same redirect → Heal page → confirmation → Heal → Safe Place path succeeded for `https://example.com`.
- No unexpected behavior observed.

**User enablement requirements (cannot be done by the app automatically)**

- User must enable **Heal Safe Place** in Safari extension settings.
- User must grant host access for `example.com`.
- Private Browsing requires a **separate** enablement toggle.

**Proven**

- Safari extension can redirect the test domain to a Heal-controlled page.
- The page can show a Heal-controlled button.
- An explicit tap can open Heal after the iOS confirmation.
- Heal can route into Safe Place.
- The flow works in normal Safari.
- The flow works in Private Browsing when separately enabled.
- Disabling the extension restores normal access.
- Unrelated domains remain unaffected by the isolated rule.

**Still unproven**

- Production-scale adult-domain coverage.
- Dynamic or remotely updated rules.
- App Store review and distribution behavior.
- Onboarding and permission-conversion rates.
- Reliability across other iOS versions.
- Production security choice between custom URL schemes and Universal Links (custom schemes are sufficient for this spike but are not strong ownership/authentication — another app could theoretically register `heal://`).

**Installed SDK / Apple-documented support (high level):** Safari Web Extensions can use `declarativeNetRequest` / `declarativeNetRequestWithHostAccess`, including `main_frame` **redirect** to an extension-bundled page. Host permissions, Private Browsing enablement, and profile permissions apply. Native messaging and App Groups can share data with the containing app; silently launching the iOS app from background extension code is **not** assumed and was **not** used.

**Status:** isolated feasibility path **device-validated as SAFARI-EXT-1** on 14 July 2026. Distinct from Apple’s Managed Settings `Website Not Allowed` page (AUTO-2 / SPECIFIC-2).

### 13.2 Coexistence with Managed Settings `.specific(...)` — 15 July 2026 (**COEXIST-SPECIFIC-1**)

**Test environment**

| Field | Value |
|---|---|
| Branch | `spike/safari-managedsettings-coexistence` |
| Baseline | `main` @ `53b9ef0` |
| Xcode | 26.6 |
| iOS SDK | 26.5 |
| Device | Physical iPhone |
| Date | 15 July 2026 |
| Safari Web Extension | Enabled (normal + Private Browsing separately) |
| Managed Settings | Named store `coexistenceSpecific`; `webContent.blockedByFilter = .specific([WebDomain(domain: "example.com")])` |
| Not tested | `.auto(...)`, website-token shields, adult-domain lists |

**Architecture tested**

```text
example.com
→ Safari (normal + Private): Safari Web Extension DNR redirect wins
  → Heal-controlled blocked.html → Open Safe Place → iOS confirm → Heal → Safe Place
→ Chrome: Managed Settings .specific filter wins
  → Apple generic Website Not Allowed (no Heal button)
```

Both mechanisms were active simultaneously on the dedicated named store plus the unchanged extension rules.

**Classification: COEXIST-SPECIFIC-1 — Safari custom intervention + Apple generic fallback**

**Normal Safari**

- `https://example.com` displayed the Heal-controlled extension page (not Apple `Website Not Allowed`).
- `Open Safe Place` worked.
- After the iOS confirmation, Heal opened into Safe Place.

**Safari Private Browsing**

- Heal-controlled extension page appeared.
- `Open Safe Place` worked.
- Heal opened into Safe Place.

**Chrome**

- Apple generic `Website Not Allowed` page appeared.
- No Heal button appeared.

**Isolation checks**

- Unrelated sites were unaffected in Safari and Chrome.
- Clearing the dedicated `.specific` store (`blockedByFilter = .none` on `coexistenceSpecific`) restored Chrome access to `example.com`.
- After disabling the Safari extension, Safari access to `example.com` was also restored.
- No unexpected behavior observed.

**Proven**

- Safari Web Extension won execution over Managed Settings `.specific(...)` in normal Safari and Private Browsing on the tested device.
- Managed Settings `.specific(...)` blocked Chrome with Apple’s generic page (blocking-only; no Heal button).
- Unrelated domains remained unaffected.
- Clearing each mechanism independently restored access for that browser path.

**Still unproven (at time of SPECIFIC spike; see §13.3 for `.auto` Stage 2A)**

- Apple classifier-selected domain coexistence (Stage 2B).
- Automatic adult-category blocking at production scale (`.auto` classifier coverage, false positives, regional behavior).
- Production-scale domain coverage and remote rule updates.
- Behavior across other iOS versions, browsers, and Safari profiles.
- Full hostname matching matrix under coexistence.

**Status:** hybrid `.specific` + Safari Web Extension **device-validated as COEXIST-SPECIFIC-1** on 15 July 2026. This does **not** solve automatic adult-category blocking.

### 13.3 Coexistence with Managed Settings `.auto(...)` Stage 2A — 15 July 2026 (**COEXIST-AUTO-1**)

**Test environment**

| Field | Value |
|---|---|
| Branch | `spike/safari-managedsettings-coexistence` |
| Baseline | `main` @ `53b9ef0` |
| Xcode | 26.6 |
| iOS SDK | 26.5 |
| Device | Physical iPhone |
| Date | 15 July 2026 |
| Safari Web Extension | Enabled (normal + Private Browsing separately); rules unchanged |
| Managed Settings | Named store `coexistenceAuto`; `webContent.blockedByFilter = .auto([WebDomain(domain: "example.com")], except: [])` |
| Mutual exclusion | Enabling Auto cleared `coexistenceSpecific`; Specific / Auto stores not left both active |
| Not tested | Stage 2B classifier-selected domain; adult-domain lists; empty `.auto()` alone for coexistence |

**Architecture tested**

```text
example.com (explicitly supplied in .auto domains set + Safari extension rule)
→ Safari (normal + Private): Safari Web Extension DNR redirect wins
  → Heal-controlled blocked.html → Open Safe Place → iOS confirm → Heal → Safe Place
→ Chrome: Managed Settings .auto filter wins
  → Apple generic Website Not Allowed (no Heal button)
```

**Important distinction:** Stage 2A used an **explicitly supplied harmless domain** inside `.auto(...)`. It proves the `.auto` **policy path** alongside the Safari extension. It does **not** prove that Apple’s adult-content classifier independently selected `example.com`, and does **not** prove coexistence for a classifier-selected adult domain.

**Classification: COEXIST-AUTO-1 — Safari custom intervention + Apple generic fallback**

Separately recorded: **Apple classifier-selected domain coexistence: unproven** (Stage 2B pending).

**Normal Safari**

- `https://example.com` displayed the Heal-controlled extension page (not Apple `Website Not Allowed`).
- `Open Safe Place` worked.
- After the iOS confirmation, Heal opened into Safe Place.

**Safari Private Browsing**

- Heal-controlled extension page appeared.
- `Open Safe Place` worked.
- Heal opened into Safe Place after confirmation.

**Chrome**

- Apple generic `Website Not Allowed` page appeared.
- No Heal button appeared.

**Isolation checks**

- Unrelated sites were unaffected in Safari and Chrome.
- Clearing the dedicated Auto store (`blockedByFilter = .none` on `coexistenceAuto`) restored Chrome access to `example.com`.
- After clearing Auto, disabling the Safari extension restored Safari access to `example.com`.
- No unexpected behavior observed.

**Proven**

- Safari Web Extension won execution over Managed Settings `.auto(...)` (with explicitly supplied `example.com`) in normal Safari and Private Browsing on the tested device.
- Managed Settings `.auto(...)` with that explicit domain blocked Chrome with Apple’s generic page (blocking-only; no Heal button).
- Unrelated domains remained unaffected.
- Clearing the Auto store and disabling the extension restored access for the respective browser paths.

**Still unproven**

- Apple classifier-selected domain coexistence (Stage 2B).
- Automatic adult-category blocking at production scale.
- Empty `.auto()` coexistence without an explicitly supplied test domain.
- Production-scale domain coverage and remote rule updates.
- Behavior across other iOS versions, browsers, and Safari profiles.

**Status:** hybrid `.auto` (explicit domain) + Safari Web Extension **device-validated as COEXIST-AUTO-1** on 15 July 2026. Automatic adult-category coexistence is **not** fully proven; Stage 2B remains pending.

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

**Status:** no Heal Control Center implementation in the codebase as of this rewrite; deferred while Safari Web Extension becomes the next intervention spike. Exact intent type (`OpenIntent` vs other App Intent patterns) should be confirmed against the installed SDK when that spike starts.

App Group is already used for shield handoff; a Control Center launch may not require a new App Group solely to open Safe Place, but any shared state should reuse existing patterns if needed (**Requires implementation design**).

---

## 15. Capability comparison matrix

| Mechanism | Auto adult block | Typed domain | Safari | Safari Private | Chrome | Heal custom shield | Action callback | Open Safe Place | Status |
|---|---:|---:|---|---|---|---|---|---|---|
| `shield.webDomains` + `WebDomainToken` | No | No (picker only) | Yes (research) | Observed after clean retest | Generic shield | Yes in Safari (research) | Yes in Safari (research) | Yes in Safari (research) | **Validated (Safari research record)** |
| `shield.webDomainCategories` + Adult token | Would have | No | In principle | Needs token | N/A | In principle | In principle | In principle | **NO-GO: no Adult token (14 Jul 2026)** |
| `blockedByFilter = .specific(...)` | No | Yes (device) | Blocks; generic page | Remained available (device; docs disagree) | Generic `Website Not Allowed` | No | No Heal button observed | No | **SPECIFIC-2 — Blocking only** |
| `blockedByFilter = .auto(...)` | Yes (tested sample) | Optional add-on | Blocks; generic page | Remained available (device; docs disagree) | Generic `Website Not Allowed` | No | No Heal button observed | No | **AUTO-2 — Blocking only** |
| Typed `WebDomain.token` → `shield.webDomains` | N/A | Attempted | N/A | N/A | N/A | N/A | N/A | N/A | **TOKEN-3 — token nil on device** |
| Safari Web Extension | With own list/classifier | Yes (`example.com` domain family) | Yes when separately enabled (device) | Yes when separately enabled (device) | N/A (extension path) | Heal-controlled page | Page button | Via `heal://safe-place` + iOS confirm | **SAFARI-EXT-1 (14 Jul 2026)** |
| Safari Web Extension + `.specific` coexistence | No | Yes (`example.com`) | Heal page (extension wins) | Heal page (extension wins) | Apple generic `Website Not Allowed` | Heal page in Safari only | Safari page button only | Safari only | **COEXIST-SPECIFIC-1 (15 Jul 2026)** |
| Safari Web Extension + `.auto` coexistence (explicit domain) | Classifier on, but test domain was explicitly supplied | Yes (`example.com` in `.auto` domains) | Heal page (extension wins) | Heal page (extension wins) | Apple generic `Website Not Allowed` | Heal page in Safari only | Safari page button only | Safari only | **COEXIST-AUTO-1 (15 Jul 2026)**; classifier-selected coexistence unproven |
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
| Heal button inside `blockedByFilter` / `Website Not Allowed` | **NO-GO (14 Jul 2026)** | AUTO-2 / SPECIFIC-2: blocks, but generic page with no Heal button; no public customization hook |
| Typed `WebDomain(domain:).token` → `shield.webDomains` | **TOKEN-3 (14 Jul 2026)** | Public token was `nil` on device |
| Chrome Network Extension / DNS / notification-first | Deferred / deprioritized | Unlikely to put a button inside Chrome’s generic shield |
| Control Center | Deferred complement | Does not solve blocking; useful after intervention path chosen |
| Safari Web Extension | **SAFARI-EXT-1 (14 Jul 2026)** | Isolated `example.com` domain-family path proven (apex + tested `www`; normal + Private when separately enabled) |
| Safari Web Extension + `.specific` coexistence | **COEXIST-SPECIFIC-1 (15 Jul 2026)** | Hybrid proven for `example.com`: extension wins in Safari; `.specific` blocks Chrome with generic page |
| Safari Web Extension + `.auto` coexistence (explicit domain) | **COEXIST-AUTO-1 (15 Jul 2026)** | Same hybrid pattern for `.auto([example.com], except: [])`; classifier-selected domain coexistence unproven (Stage 2B) |
| Hard-coding / decoding opaque tokens | Rejected | Private/unsupported; App Review risk |

---

## 17. Open questions and required device spikes

### Resolved by `blockedByFilter` spike (14 July 2026)

1. `.auto` UI: Apple generic **`Website Not Allowed`** (not Heal custom).
2. `.specific` UI: same generic page.
3. Usable Heal button on either filter page: **no**.
4. Open Heal / Safe Place from either filter page: **no**.
5. Typed `WebDomain(domain:).token` usable for `shield.webDomains`: **no** (`nil` → TOKEN-3).
6. Chrome under `.auto` / `.specific`: same generic blocking (Incognito not separately recorded).
7. Safari Private Browsing under both policies on the tested device: **remained available** (conflicts with Apple documentation wording; interpret cautiously).
8. Tested subdomain under `.specific`: also blocked (not a full matching-rules specification).

### Still open / next spikes

1. ~~Safari Web Extension minimal redirect → Heal page → Safe Place~~ — **Done: SAFARI-EXT-1 (14 July 2026)** for isolated `example.com` domain family (apex + tested `www`; normal + Private when separately enabled).
2. ~~Execution order when both extension redirect and `.specific` blockedByFilter are active~~ — **Done: COEXIST-SPECIFIC-1 (15 July 2026)** for `example.com`; Safari extension wins in normal + Private Safari; `.specific` provides Chrome blocking-only fallback.
3. ~~Execution order when both extension redirect and `.auto` blockedByFilter are active with an explicitly supplied domain~~ — **Done: COEXIST-AUTO-1 (15 July 2026)** for `example.com` in `.auto` domains set; Safari extension wins in normal + Private Safari; `.auto` provides Chrome blocking-only fallback. Classifier-selected domain coexistence remains Stage 2B.
4. Production routing security: custom URL scheme vs Universal Links (spike used `heal://safe-place`; scheme ownership is weak).
5. Extension behavior across additional Safari profiles / OS versions.
6. Apple classifier-selected domain coexistence with Safari Web Extension (**Stage 2B — unproven**).
7. Broader real-world coverage quality / false positives of Apple’s `.auto` classifier.
8. Full hostname matching matrix for `.specific` / `.auto` (`www`, public suffix, IDN, ports, schemes) under coexistence.
9. Chrome Incognito under `blockedByFilter` (not recorded in the completed spike).
10. Production entitlement / App Review / onboarding conversion for Safari Extension distribution.
11. Production-region impact of `FamilyActivityData` EU limits (relevant if any future feature depends on data access).
12. Control Center Safe Place entry as a complementary non-blocking path.
13. Production-scale adult-domain list / dynamic or remote DNR rules for the Safari extension.

---

## 18. Recommended research sequence

### Completed branch

```text
spike/web-content-filter-behavior
```

Created from `main @ 48ef0f1`. Device results recorded in this document (AUTO-2 / SPECIFIC-2 / TOKEN-3). Spike implementation was temporary and is not retained as product code.

### Completed Safari extension branch (14 July 2026)

```text
spike/safari-web-extension-block-page
```

**Result: SAFARI-EXT-1** — see §13.1. Primary redirect test kept Managed Settings website filters cleared. Coexistence / ordering vs `blockedByFilter` was **not** tested in that branch.

### Completed coexistence branch (15 July 2026)

```text
spike/safari-managedsettings-coexistence
```

**Result: COEXIST-SPECIFIC-1** — see §13.2. Safari Web Extension + named-store `.specific([WebDomain(domain: "example.com")])` active together. Safari (normal + Private): extension won → Heal page + Safe Place. Chrome: Apple generic `Website Not Allowed`. Unrelated sites unaffected. Clearing `.specific` restored Chrome; disabling extension restored Safari.

**Result: COEXIST-AUTO-1** — see §13.3. Same branch; named-store `coexistenceAuto` with `.auto([WebDomain(domain: "example.com")], except: [])` + unchanged Safari extension. Safari (normal + Private): extension won → Heal page + Safe Place. Chrome: Apple generic `Website Not Allowed`. Unrelated sites unaffected. Clearing Auto restored Chrome; disabling extension restored Safari. Explicit-domain `.auto` policy path proven; **Apple classifier-selected domain coexistence: unproven** (Stage 2B pending).

Chrome may remain **blocking-only** via `.auto` / `.specific` in a hybrid architecture. **COEXIST-SPECIFIC-1** and **COEXIST-AUTO-1** validate that hybrid for explicitly supplied `example.com`. Automatic adult-category coexistence is not fully proven.

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
| 14 July 2026 | **AUTO-2** for `.auto` | Real-device: blocks tested adult site; `Website Not Allowed`; no Heal button |
| 14 July 2026 | **SPECIFIC-2** for `.specific` | Real-device: blocks typed domain + tested subdomain; same generic page; no Heal button |
| 14 July 2026 | **TOKEN-3** for typed `WebDomain.token` | Real-device: public token was `nil` |
| 14 July 2026 | NO-GO Heal button inside `blockedByFilter` | Installed SDK + real-device; not a Family Controls whole-product NO-GO |
| 14 July 2026 | Private Browsing remained available under both filters | Point-in-time device result; conflicts with Apple docs wording — interpret cautiously |
| 14 July 2026 | Next: Safari Web Extension block-page spike | Only remaining supported candidate for Heal-controlled Safari intervention UI |
| 14 July 2026 | **SAFARI-EXT-1** for Safari Web Extension | Real-device: `example.com` domain family (apex + tested `www`) → Heal `blocked.html` → confirm → Heal → Safe Place; normal + Private; unrelated sites unaffected; disable restores access |
| 15 July 2026 | **COEXIST-SPECIFIC-1** for extension + `.specific` coexistence | Real-device: Safari extension wins (normal + Private) → Heal page + Safe Place; Chrome → Apple generic page; unrelated sites unaffected; clear `.specific` restores Chrome; disable extension restores Safari |
| 15 July 2026 | **COEXIST-AUTO-1** for extension + `.auto` coexistence (explicit domain) | Real-device Stage 2A: `.auto([example.com], except: [])` + extension; Safari wins (normal + Private) → Heal page + Safe Place; Chrome → Apple generic page; unrelated sites unaffected; clear Auto restores Chrome; disable extension restores Safari |
| 15 July 2026 | Apple classifier-selected domain coexistence unproven | Stage 2B pending; Stage 2A does not prove classifier independently selected `example.com` |

---

## 20. Source and evidence references

### Project artifacts

- `docs/Spike-Validation-Report.md` — formal app-shield validation; Safari Web Extension SAFARI-EXT-1; coexistence COEXIST-SPECIFIC-1 and COEXIST-AUTO-1 records.
- `Heal/CoexistenceSpecificFilterService.swift` — named store `coexistenceSpecific`, `blockedByFilter = .specific` spike helper.
- `Heal/CoexistenceAutoFilterService.swift` — named store `coexistenceAuto`, `blockedByFilter = .auto` Stage 2A spike helper.
- `HealSafariExtension/` — Manifest V3 static DNR redirect spike (`example.com` domain family → `blocked.html`).
- `Heal/Info.plist`, `Heal/HealApp.swift`, `Heal/SpikeAppState.swift` — `heal://safe-place` deep-link routing into existing Safe Place presentation.
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

## 22. Point-in-time conclusion (15 July 2026)

For **website** intervention with a custom Heal shield and Safe Place button, the only end-to-end path recorded as working in Safari is picker-selected `WebDomainToken` shielding via `store.shield.webDomains`.

Separately, the **app** shield path is formally validated in `docs/Spike-Validation-Report.md`.

As of Xcode 26.6 and iOS SDK 26.5 on the tested device, Family Controls does **not** expose a public Adult/Pornography `ActivityCategoryToken` (picker inspection + full `FamilyActivityData.activityCategories` enumeration of 12 categories). That path is **NO-GO** for category-token adult website shielding.

Separately, `webContent.blockedByFilter` was device-tested on 14 July 2026:

- **AUTO-2:** `.auto` can block a tested adult site (coverage not fully proven) and shows generic **`Website Not Allowed`** with **no Heal button**.
- **SPECIFIC-2:** `.specific` can block a manually entered domain (and a tested subdomain) with the same generic page and **no Heal button**.
- **TOKEN-3:** typed `WebDomain(domain:).token` was `nil`; no public bridge into custom `shield.webDomains`.

**NO-GO as of 14 July 2026 / Xcode 26.6 / iOS SDK 26.5** for adding a Heal button inside the `blockedByFilter` experience. This does **not** make Family Controls as a whole a NO-GO: app shielding and picker-token website shielding remain separate validated/researched mechanisms. Blocking success without intervention is only a partial product result.

The Safari Web Extension isolated path is **device-validated as SAFARI-EXT-1** (14 July 2026): static DNR `main_frame` redirect for the `example.com` domain family (apex and tested `www` subdomain) → Heal-controlled `blocked.html` → explicit tap → iOS confirmation → Heal → Safe Place (normal Safari and Private Browsing when separately enabled).

**COEXIST-SPECIFIC-1** (15 July 2026) validates a hybrid for `example.com`: when the Safari Web Extension and Managed Settings `.specific([WebDomain(domain: "example.com")])` are both active, the extension wins in normal and Private Safari (Heal-controlled page + Safe Place path), while Chrome shows Apple’s generic `Website Not Allowed` page with no Heal button. Unrelated sites were unaffected; clearing the dedicated `.specific` store restored Chrome access; disabling the extension restored Safari access.

**COEXIST-AUTO-1** (15 July 2026, Stage 2A) validates the same hybrid pattern when the Managed Settings policy is `.auto([WebDomain(domain: "example.com")], except: [])` on named store `coexistenceAuto`: Safari extension wins in normal and Private Safari; Chrome shows Apple generic `Website Not Allowed`. Clearing Auto restored Chrome; disabling the extension restored Safari. This proves the `.auto` **policy path** with an explicitly supplied harmless domain. **Apple classifier-selected domain coexistence remains unproven** (Stage 2B). Automatic adult-category blocking at production scale is **not** solved by these spikes.

A hybrid may keep `.specific` / `.auto` as Chrome/other-browser **blocking-only** fallback while the Safari Web Extension supplies intervention UI in Safari. Control Center remains a complementary non-blocking entry path. Production-scale domain coverage, remote rules, App Review, and Universal Links vs custom schemes remain open.
