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

## Scope control

For every milestone:

- Touch only the approved files.
- Do not continue to the next milestone.
- Do not add product features early.
- Do not add backend, analytics, notifications, DeviceActivity, categories, domains, feed/reels, or video unless explicitly approved.
- If more files are needed than planned, stop and ask first.

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

## Completion rule

A milestone is not complete just because the build passes.

A milestone is complete only when:

- the intended behavior works
- the code lives in the right place
- scope was respected
- warnings in touched files are handled or explicitly justified
- the change can be explained clearly
