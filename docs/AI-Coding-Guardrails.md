# AI Coding Guardrails

This document defines concise coding rules for AI-assisted development in the Heal / Safe Place spike.

## Goal

Move fast through technical milestones without creating spaghetti code.

The priority is not only to make the code work, but to make the code work in the correct place.

## Responsibility boundaries

Before implementing any change, identify where the responsibility belongs:

- Views: UI only. Display state and trigger actions.
- AppState: app-level state, routing decisions, and orchestration.
- Services / Stores: technical operations, persistence, Apple API wrappers.
- Extensions: only the work that must happen inside the extension.

Do not mix UI, persistence, routing, Apple API logic, and extension logic in the same place unless explicitly approved.

## Current intended ownership

- AppSelectionView: displays selected app state and shield controls.
- SpikeAppState: owns app-level spike state and orchestration.
- ShieldService: applies and clears ManagedSettings shields only.
- HandoffWriter: writes the App Group handoff marker from the Shield Action extension only.
- HandoffStore: reads and consumes the App Group handoff marker in the main app only.
- ShieldActionExtension: handles shield button actions and must call completionHandler exactly once.
- ShieldConfigurationExtension: defines custom shield text/buttons only.
- SafePlaceView: temporary spike placeholder; it does not define final product architecture.



## Prompt strictness levels

Use different levels of prompt strictness depending on task size.

### Full milestone prompt

Use for risky or multi-file work, especially:

- Xcode targets, extensions, signing, entitlements, capabilities, App Groups
- lifecycle, routing, persistence, navigation, security, or user data
- unfamiliar architecture
- work that requires real-device validation
- work where the AI could easily expand beyond the spike

The prompt should cover: milestone/goal, current state, expected direction, expected files, files requiring approval before editing, out of scope, requirements, verification, and stopping condition.

### Short fix prompt

Use for isolated and reversible changes when:

- the exact file or function is known
- no architecture decision is involved
- verification is simple

The prompt should cover: exact problem, expected file/function, smallest correct change, no refactor/no abstractions, and verification result.

### Emergency build-error prompt

Use for concrete build or runtime errors.

The AI must: inspect before editing, identify likely root cause, make the smallest root-cause fix, avoid unrelated refactors, repeat the failing build/reproduction, and report the exact verification result.

## Scope control

For every milestone:

- Touch only approved files.
- Do not continue to the next milestone.
- Do not add product features early.
- Do not add backend, analytics, notifications, DeviceActivity, categories, domains, feed/reels, or video unless explicitly approved.

Expected files are guidance, not always a complete allowlist.
If another file must be changed, stop before editing it and request approval.

Sensitive files still require explicit approval before editing:

- signing
- entitlements
- capabilities
- Xcode project settings
- target membership
- dependencies
- Shield Action / Shield Configuration paths unless the milestone explicitly targets them



## Avoid spaghetti code

Avoid:

- views that perform persistence directly
- Shield logic inside views
- Safe Place routing inside ShieldService
- App Group marker writing outside HandoffWriter
- handoff reading duplicated outside HandoffStore
- multiple sources of truth for the same state
- new managers/services that duplicate existing ones
- broad file changes for a small milestone
- build fixes that rewrite unrelated architecture



## Comments policy

Use comments sparingly.

Good comments explain:

- why something exists
- scope boundaries
- temporary spike decisions
- Apple platform constraints
- non-obvious safety decisions

Avoid comments that only repeat the code.

Comments must stay up to date.
A stale comment is worse than no comment.

## Temporary spike code

Temporary code must be labeled clearly.

Example:

```swift
// Spike-only placeholder. Final Safe Place may later become the home feed,
// a reels-style experience, or a dedicated intervention screen.
```

Temporary spike code must not silently become final product architecture.

## Build fixes

When fixing build errors:

- fix the local cause
- do not change unrelated files
- do not rewrite architecture unless required
- report exactly what caused the error
- state whether the fix changed behavior or only compilation



## Red flags

Stop and ask before continuing if:

- one view starts handling UI, persistence, routing, and Apple APIs together
- a new service duplicates an existing one
- the same state is stored in multiple places
- a milestone requires unexpectedly broad file changes
- a temporary workaround affects product architecture
- responsibility placement is unclear
- a service and a view both store writable copies of the same state
- a local display state is treated as persistent product state
- multiple views independently refresh the same mutable shared service
- a callback, foreground refresh, and onAppear can race or duplicate work
- an old error can remain visible after successful state recovery

## Review escalation

After implementation, choose the review depth according to risk.

A focused Change Report and diff are sufficient only for small, isolated,
reversible changes.

Request a full review bundle before commit when the change includes:

- state or persistence
- services or stores
- URL routing or navigation
- lifecycle or concurrency
- interaction between multiple views
- shared ownership
- a meaningful architectural decision

The bundle must contain branch/status, the exact diff, full changed files, and
relevant context files.

Do not commit architecture-sensitive changes until:

1. Ownership and data flow were reviewed.
2. Duplicate sources of truth and lifecycle risks were checked.
3. Required device testing passed.

### Documentation evolution

Record important architectural knowledge while the system is built. Do not rely
on a later audit to reconstruct missing reasoning.

Require a documentation-impact review when a change:

- introduces or changes state ownership;
- adds or changes persistence;
- adds a service or backend integration;
- changes routing or navigation;
- changes lifecycle or concurrency behavior;
- changes cross-view or cross-component data flow;
- introduces or changes a source of truth;
- changes an internal or external contract;
- adds or changes migration, deployment, deletion, recovery, release, setup, or
  operational procedures;
- makes, changes, or supersedes a significant architectural decision.

Documentation types:

- **ADR** — decision, context, alternatives, consequences, and status.
- **Architecture overview** — current component boundaries, ownership, and
  sources of truth.
- **Data-flow/state-machine documentation** — runtime flow, transitions, and
  lifecycle behavior.
- **Runbook** — setup, migration, deployment, release, recovery, testing, or
  operational procedures.

Documentation must describe the implemented system, not speculative future
architecture.

Historical ADRs should normally be marked `superseded` and linked to their
replacement rather than deleted.

A later documentation audit may verify completeness, but it must not be relied
on to reconstruct missing architectural reasoning.

Documentation-only follow-up changes may use focused diff review unless they
alter an approved architecture or product decision.

Trivial copy, styling, or isolated implementation changes normally require only
a documented `no` conclusion in the Change Report, not new architecture
documentation. Report the Documentation Impact fields using
[AI Change Report Protocol](AI-Change-Report-Protocol.md).

## Completion rule

A milestone is not complete just because the build passes.

A milestone is complete only when:

- the intended behavior works
- the code lives in the right place
- scope was respected
- warnings in touched files are handled or explicitly justified
- the change can be explained clearly
- required documentation from the Documentation Impact assessment is included
  or explicitly deferred with reviewer approval

