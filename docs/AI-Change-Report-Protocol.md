# AI Change Report Protocol

**Location:** `docs/AI-Change-Report-Protocol.md`  
**Related:** [Feasibility Research Plan](Feasibility-Research-Plan.md) · [Spike Implementation Checklist](Spike-Implementation-Checklist.md) · [AI Coding Guardrails](AI-Coding-Guardrails.md)

Purpose:  
After every implementation change, the AI/developer must produce a short but precise report that explains not only **what changed**, but also **how it was implemented**, so the reviewer can verify that the agreed plan was followed and that the code quality did not drift.

Use this protocol for the Safe Place / Heal iOS spike.

---

## Core Rule

After every code or project-configuration change, stop and report.

Do not continue to the next milestone until the user/reviewer confirms.

Each report must answer:

1. What changed?
2. Which files changed?
3. How was it implemented?
4. Why was it implemented this way?
5. Did it stay inside the approved scope?
6. How should it be tested?
7. Are there risks, shortcuts, or known issues?
8. Did the touched files build without unresolved warnings?

---



## Before Making Changes

Before touching files, provide a short implementation plan.

Required format:

```md
## Planned Change

Milestone:
<Milestone name>

Goal:
<What this change is meant to prove or enable>

Files I plan to touch:
- <file path> — <reason>
- <file path> — <reason>

Files I will not touch:
- <file path or area>
- <file path or area>

Implementation approach:
<Short explanation of how I will implement this>

Out of scope:
<List anything that must not be added in this change>

Expected test:
<How the user should test this after implementation>
```

Wait for confirmation before implementing.

---



## After Making Changes

After implementation, provide a report.

### Full Change Report (milestones)

Use the full report for milestone work. Use this header:

```md
# Change Report — <Milestone Name>
```

Fill all sections:

1. Milestone
2. Goal
3. Files Changed
4. What Changed
5. How It Was Implemented
6. Scope Check
7. Code Quality Notes
8. Build Status
9. Warnings Status
10. How To Test Manually
11. Expected Result
12. Known Issues / Follow-ups
13. Suggested Git Commit

### Compact report (small isolated fixes)

For short fixes and emergency build-error fixes, use a compact report instead:

- Files changed
- What changed
- Verification result
- Anything not verified
- Scope deviation, if any

For documentation-only changes, use the compact report unless the reviewer asks for a full report.

The full milestone report format remains required for milestone work.
Do not weaken the rule to stop after each milestone.

---



## Scope Control

The approved milestone prompt is the current source of truth for scope.

Do not continue to the next milestone, add unrequested product features, or modify
sensitive project areas unless the current prompt explicitly allows it.

If implementation requires work outside the approved scope, stop and request approval
before editing.

For architecture-sensitive changes, include ownership and lifecycle, data flow,
alternatives considered, architectural risks, and the required review level described
in [AI Coding Guardrails](AI-Coding-Guardrails.md).

---



## Reviewer-Focused Requirements

The report must be detailed enough that a reviewer can detect:

- Whether the AI followed the approved scope.
- Whether it changed unexpected files.
- Whether it used the correct Apple API.
- Whether the implementation creates bad architecture.
- Whether temporary spike code is clearly marked.
- Whether the next step is safe to proceed.

Avoid vague summaries like:

> “Implemented authorization.”

Instead write:

> “Created `AuthorizationService`, which wraps `AuthorizationCenter.shared.requestAuthorization(for: .individual)`. `SetupView` calls the service through `SpikeAppState`, then updates local authorization state for display. No picker, shield, App Group, or Safe Place logic was added.”

---



## Required Response After Every Change

Choose the report level by task size (see [AI Coding Guardrails](AI-Coding-Guardrails.md) — Prompt strictness levels).

**Milestones:** use the full Change Report (sections 1–13 below).

**Small isolated fixes:** use the compact report (Files changed, What changed, Verification result, Anything not verified, Scope deviation if any).

Full milestone sections:

1. Milestone
2. Goal
3. Files Changed
4. What Changed
5. How It Was Implemented
6. Scope Check
7. Code Quality Notes
8. Build Status
9. Warnings Status
10. How To Test Manually
11. Expected Result
12. Known Issues / Follow-ups
13. Suggested Git Commit

---



## Rule For Build And Warnings

After every implementation change, do not report “done” only because the project builds.

The AI/developer must also check for warnings in every file touched by the current change.

If Xcode shows warnings in touched files, report them and either:

- Fix them within the approved scope, or
- Ask the reviewer before changing additional scope.

Warnings that must be reported include, but are not limited to:

- Switch must be exhaustive.
- Availability warnings.
- Unused code.
- Wrong template leftovers.
- Target membership issues.
- Entitlement/capability mismatch.

Every Change Report must include:

```text
Build:
- Build succeeded / failed / not run

Warnings:
- No warnings in touched files
or
- List warnings in touched files and how they were handled

Scope:
- Confirm no unrelated milestone was modified
```

Do not continue to the next milestone while there are unresolved warnings in files touched during the current milestone, unless the reviewer explicitly approves leaving them.

### Swift Enum Switches

- Do not leave empty cases.
- Do not use `fatalError()` in app extension handling unless explicitly approved.
- If the enum may grow and Xcode still warns, use a safe default fallback for spike UI mapping.
- For `ShieldAction` handling, every case must call `completionHandler` exactly once.



### Apple Template Files

- Do not assume the generated template is correct.
- Verify the class/protocol matches the target type.
- Shield Configuration Extension should use the Shield Configuration template/protocol.
- Shield Action Extension should use `ShieldActionDelegate`.
- If a target appears to have the wrong template, stop and report it before modifying it.

---



## Rule For Uncertainty

If the AI is unsure whether a change is correct, it must say so explicitly.

Required wording:

```text
Uncertainty:
<I am not fully sure about...>

Suggested validation:
<How to verify it in Xcode / on device / in Apple documentation>
```

Do not hide uncertainty behind confident wording.

---



## Rule For Apple/Xcode Project Changes

If the AI edits project configuration, entitlements, or `.pbxproj`, it must explain:

- Which target was affected.
- Which capability or entitlement was added.
- Whether it applies to the main app, Shield Configuration extension, or Shield Action extension.
- Why the change belongs to the current milestone.
- Whether the same change is needed on other targets later.

---



## Rule For Generated Code

When code is added, the report must identify:

- New types/classes/structs.
- New methods.
- Which file owns which responsibility.
- How state is passed.
- What is spike-only.
- What will need revisiting before production.

---



## Final Instruction To AI Developer

After every implementation step, produce a Change Report before continuing.

Do not chain multiple milestones together.

Do not silently expand scope.

Do not continue after a build failure without reporting the failure and asking how to proceed.

Do not continue after unresolved warnings in files touched during the current milestone unless the reviewer explicitly approves leaving them.