//
//  ProtectionRepairView.swift
//  Heal
//
//  Post-completion combined repair screen and host. Derives issues from live
//  technical owners + historical M5 SWF decision. Views trigger actions only.
//  Live SWF state is owned by observable SystemWebFilteringService.shared.
//  Session-only bypass lives in ProtectionRepairSession (HealApp-scoped).
//

import SwiftUI

/// Routes completed users to the combined repair screen when unresolved issues
/// exist, otherwise to the existing post-onboarding root. While Safari
/// enablement is still `.checking`, shows a brief loading state so a known-false
/// disabled assumption cannot flash the repair UI.
struct ProtectionRepairHost: View {
    @Bindable var appState: SpikeAppState
    @Bindable var onboarding: OnboardingProgress
    @Bindable var repairSession: ProtectionRepairSession
    @Environment(\.scenePhase) private var scenePhase

    @State private var safariEnablement = SafariExtensionEnablementModel()
    /// Shared observable technical owner — not a view-local SWF snapshot.
    @State private var systemFiltering = SystemWebFilteringService.shared
    /// Ephemeral action/status copy only. Not live filter truth.
    @State private var systemFilterMessage: String?

    private var repairIssues: [ProtectionRepairIssue] {
        ProtectionRepairEvaluator.issues(
            isAuthorizationApproved: appState.isAuthorizationApproved,
            safariExtensionState: safariEnablement.extensionState,
            systemWebFilteringDecision: onboarding.systemWebFilteringDecision,
            systemFilterState: systemFiltering.filterState
        )
    }

    private var isAwaitingInitialSafariState: Bool {
        if case .checking = safariEnablement.extensionState {
            return true
        }
        return false
    }

    var body: some View {
        Group {
            if isAwaitingInitialSafariState {
                ProgressView("Checking protection status...")
                    .padding()
            } else if repairIssues.isEmpty {
                PostOnboardingRootView(appState: appState)
            } else {
                ProtectionRepairView(
                    appState: appState,
                    onboarding: onboarding,
                    repairSession: repairSession,
                    safariEnablement: safariEnablement,
                    systemFiltering: systemFiltering,
                    systemFilterMessage: $systemFilterMessage,
                    repairIssues: repairIssues,
                    onRefreshLiveState: refreshLiveState
                )
            }
        }
        .onAppear {
            refreshLiveState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }
            refreshLiveState()
        }
    }

    private func refreshLiveState() {
        appState.refreshAuthorizationStatus()
        safariEnablement.refresh()
        systemFiltering.refreshFilterState()
        clearStaleActionMessageIfNeeded()
    }

    private func clearStaleActionMessageIfNeeded() {
        switch systemFiltering.filterState {
        case .enabled, .cleared:
            systemFilterMessage = nil
        case .error:
            break
        }
    }
}

struct ProtectionRepairView: View {
    @Bindable var appState: SpikeAppState
    @Bindable var onboarding: OnboardingProgress
    @Bindable var repairSession: ProtectionRepairSession
    @Bindable var safariEnablement: SafariExtensionEnablementModel
    @Bindable var systemFiltering: SystemWebFilteringService
    @Binding var systemFilterMessage: String?
    let repairIssues: [ProtectionRepairIssue]
    let onRefreshLiveState: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Protection Needs Attention")
                    .font(.largeTitle.bold())

                Text(
                    "Heal detected one or more protection mechanisms that are not "
                        + "currently available. Fix each item below, or continue to "
                        + "the app for this session only."
                )
                .font(.body)
                .foregroundStyle(.secondary)

                ForEach(repairIssues) { issue in
                    repairIssueSection(issue)
                }

                Button {
                    repairSession.deferRepairForCurrentSession()
                } label: {
                    Text("Continue to App for Now")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Text(
                    "Continue suppresses this screen only until you fully quit the "
                        + "app. Unresolved issues return on the next cold launch. "
                        + "This does not mark protections as repaired and does not "
                        + "change your onboarding decisions."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func repairIssueSection(_ issue: ProtectionRepairIssue) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            switch issue {
            case .screenTimeAuthorization:
                screenTimeRepairSection
            case .safariExtension:
                safariExtensionRepairSection
            case .systemWebFiltering:
                systemWebFilteringRepairSection
            }
        }
    }

    private var screenTimeRepairSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screen Time Access")
                .font(.title2.bold())

            Text(
                "Screen Time authorization is not approved. Apple protection "
                    + "controls, including app-shield and ManagedSettings operations, "
                    + "are unavailable until access is restored."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            ScreenTimeAuthorizationSection(appState: appState)
        }
    }

    private var safariExtensionRepairSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safari Extension")
                .font(.title2.bold())

            Text(
                "Warning: Safari protection is inactive. The Heal Safari "
                    + "extension is not currently detected as enabled."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            SafariExtensionEnablementSection(
                model: safariEnablement,
                refreshesWithLifecycle: false
            )

            if systemFiltering.filterState == .enabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text(
                        "System Website Filtering is currently active. On tested "
                            + "devices, an active filter may grey out Safari extension "
                            + "settings. Disable the filter here to recover access to "
                            + "extension settings, then enable the extension. This does "
                            + "not change your historical System Website Filtering "
                            + "onboarding decision."
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)

                    if let systemFilterMessage {
                        Text(systemFilterMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        disableSystemWebsiteFiltering()
                    } label: {
                        Text("Disable System Website Filtering")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var systemWebFilteringRepairSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Website Filtering")
                .font(.title2.bold())

            Text(
                "Your onboarding decision was to enable System Website Filtering, "
                    + "but the live filter is not currently enabled. Live state is "
                    + "owned by SystemWebFilteringService; the historical decision is "
                    + "unchanged until you act."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            if !appState.isAuthorizationApproved {
                Text(
                    "Screen Time access must be restored first. System Website "
                        + "Filtering cannot be enabled until Screen Time authorization "
                        + "is approved. Restoring access does not enable the filter "
                        + "automatically — tap Enable after authorization succeeds."
                )
                .font(.body)
                .foregroundStyle(.secondary)
            }

            Text(onboardingDecisionLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(systemFilterStateLabel)
                .font(.headline)
                .foregroundStyle(systemFilterStateColor)

            if case .error(let message) = systemFiltering.filterState {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let systemFilterMessage {
                Text(systemFilterMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                enableSystemWebsiteFiltering()
            } label: {
                Text("Enable System Website Filtering")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!appState.isAuthorizationApproved)
        }
    }

    private var onboardingDecisionLabel: String {
        switch onboarding.systemWebFilteringDecision {
        case .enabled:
            return "Onboarding decision: Enabled"
        case .skipped:
            return "Onboarding decision: Skipped"
        case nil:
            return "Onboarding decision: None"
        }
    }

    private var systemFilterStateLabel: String {
        switch systemFiltering.filterState {
        case .enabled:
            return "Filter state: enabled"
        case .cleared:
            return "Filter state: cleared"
        case .error:
            return "Filter state: error"
        }
    }

    private var systemFilterStateColor: Color {
        switch systemFiltering.filterState {
        case .enabled:
            return .green
        case .cleared:
            return .secondary
        case .error:
            return .red
        }
    }

    private func enableSystemWebsiteFiltering() {
        guard appState.isAuthorizationApproved else {
            return
        }

        systemFilterMessage = nil
        do {
            try systemFiltering.enableSystemWebsiteFiltering()
            onRefreshLiveState()
            guard systemFiltering.filterState == .enabled else {
                systemFilterMessage =
                    "Could not enable system website filtering: verification did not report enabled."
                return
            }
            // Historical M5 decision already `.enabled` — do not rewrite onboarding.
            systemFilterMessage = "System website filtering enabled."
        } catch {
            onRefreshLiveState()
            systemFilterMessage =
                "Could not enable system website filtering: \(error.localizedDescription)"
        }
    }

    private func disableSystemWebsiteFiltering() {
        systemFilterMessage = nil
        do {
            try systemFiltering.disableSystemWebsiteFiltering()
            onRefreshLiveState()
            guard systemFiltering.filterState == .cleared else {
                systemFilterMessage =
                    "Could not disable system website filtering: verification did not report cleared."
                return
            }
            // Does not alter the historical M5 decision.
            systemFilterMessage = "System website filtering disabled."
        } catch {
            onRefreshLiveState()
            systemFilterMessage =
                "Could not disable system website filtering: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ProtectionRepairHost(
        appState: SpikeAppState(),
        onboarding: OnboardingProgress(),
        repairSession: ProtectionRepairSession()
    )
}
