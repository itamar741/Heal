# Investigation — Safari protection-test first-navigation failure

Branch: `investigation/safari-first-navigation-cold-start`  
Base: `752a41b6baed7d3ef496f8bf70c5edcf9bd7bc83` (merged M7 / `github/master`)

## Classification (evidence-based)

**Intermittent first-navigation miss of the dedicated Safari protection-test DNR redirect on an app-initiated navigation.**

Scope limits (required):

- The observed failure is proven only for the dedicated protection-test rule and URL (`heal_safari_protection_test` → `https://example.com/heal-safari-protection-test` → `/blocked-test.html`).
- This investigation did **not** establish whether the production domain-blocking rules in `HealSafariExtension/Resources/rules.json` exhibit the same behavior.
- No safe neutral production-rule target existed in the ruleset, so that question remains untested.
- Do **not** generalize this result to all Safari DNR rules or all blocked websites.

Not deterministic. Not clean-install-only.

## Device-test matrix (completed)

### Existing installation after ~two days without testing

| Step | Result |
|------|--------|
| First app-initiated protection test | Safari opened; blank/stalled page |
| Diagnostics | `UIApplication.open` accepted; pending created; Heal inactive/background; no Safari callback |
| Manual address-bar resubmit of same URL | Custom blocked-test page |
| Immediate later tests | Blocked page without manual resubmit |
| Later callback within 5-minute window | `pending_before=true`, `marked_passed=true`, Safe Place routing requested |

### Safari force-quit

| Step | Result |
|------|--------|
| Remove Safari from app switcher, then two consecutive protection tests | Both succeeded immediately |

Force-quitting Safari alone did **not** reproduce the DNR failure in this controlled run.

### Device restart

| Step | Result |
|------|--------|
| Controlled first post-restart protection test | Custom blocked page immediately |

Restarting the device alone did **not** reproduce the DNR failure in this controlled run.

Pre-restart pending observation is recorded separately below; it is **not** Safari DNR evidence.

### Install over existing app (many Debug redeploys)

| Outcome | Notes |
|---------|--------|
| Mixed first attempts | Custom blocked page **or** normal Example Domain **or** blank/indefinitely loading Example Domain |
| Failed attempts | Manual resubmit of same URL → custom blocked page |
| Heal closed vs backgrounded before deploy | More successes observed in part of the sample when Heal was closed first; failures and successes occurred in **both** conditions |

Do **not** claim a causal relationship between Heal process state and outcome.

### Clean installation

| Step | Result |
|------|--------|
| Delete + reinstall, first test | Blank/stalled page |
| Immediate second test | Custom blocked page |

## Facts established

- `UIApplication.open` accepted the navigation.
- The pending attempt was created.
- Heal moved inactive/background.
- On failed first navigations, no test callback returned.
- Safari displayed either a blank/stalled load or normal Example Domain.
- Manually resubmitting the unchanged URL recovered every failed attempt observed in the recorded matrix.
- Once the custom blocked-test page appeared, callback validation, pass marking, and Safe Place routing worked.
- The failure was not limited to clean installations.
- Clean installation, deployment, and extended inactivity may affect probability, but none is proven as the sole trigger.
- Safari force-quit and device restart did not independently reproduce the DNR failure in the controlled attempts.

## Hypotheses still unproven

- A cold extension or ruleset-readiness race remains a hypothesis only.
- Any sole trigger among clean install, redeploy, or inactivity.
- Causal link from Heal foreground/background/closed state at deploy time.
- Whether production (`heal_domain_blocklist` / `rules.json`) DNR misses on the same intermittent first navigation (untested; no safe in-ruleset probe host).

## Separate observation — restart and pending validity

Not Safari DNR evidence. Inconclusive.

- A pending attempt is persisted in `UserDefaults` and is valid for five minutes.
- Restarting the device does not intentionally invalidate it.
- A callback after restart should still mark the test passed if it arrives within the five-minute validity window.
- Failure to mark it passed is expected only if the five-minute window expired.
- If the behavior occurred within five minutes, it may represent a separate pending-state or UI-consistency issue.
- The exact elapsed time was not captured, so this observation is inconclusive and must not be used as Safari DNR evidence.

## Separate observation — Screen Time authorization

Not Safari DNR evidence. Not diagnosed on this branch.

- On some cold launches, the app briefly displayed `notDetermined` and the Screen Time setup screen while Settings still showed authorization approved.
- It self-corrected within approximately one second or after lifecycle refresh.
- This is a separate launch-state issue.

## Production-rule probe inspection (no rules changed)

Inspected: `HealSafariExtension/Resources/rules.json` (63,311 rules), `Tools/SafariDomainRules/local-additions.json` (empty), `Tools/SafariDomainRules/allowlist.json` (empty), `docs/safari-domain-rules.md`.

- Production list purpose: verified-license adult / pornography / snuff hosts imports.
- Every rule: `urlFilter` `||<hostname>^`, `resourceTypes: ["main_frame"]`, redirect `/blocked.html`.
- No `example.com` (or other neutral host) present; `local-additions.json` empty.

**No safe existing production-rule target found.** No hostname invented; ruleset not modified.

## Functional-test path (reference)

- App opens `https://example.com/heal-safari-protection-test` via `UIApplication.shared.open`.
- Static ruleset `heal_safari_protection_test` → `/blocked-test.html`.
- CTA: `heal://safe-place?source=safariProtectionTest`.

Temporary diagnostic instrumentation used during device runs was removed from the working tree after the matrix completed; it is not part of the final docs-only change.
