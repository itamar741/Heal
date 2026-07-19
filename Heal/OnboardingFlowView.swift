//
//  OnboardingFlowView.swift
//  Heal
//
//  Onboarding shell through M6 Finish Setup: explanation, Screen Time, Safari
//  enablement, manual All Websites / Private Browsing confirmations, Safari
//  functional protection test, optional System Website Filtering consent, and
//  explicit Finish Setup. Visible step is derived from OnboardingProgress flags,
//  live SpikeAppState authorization, live Safari extension enablement,
//  SafariProtectionTestStore status, and live SystemWebFilteringService state
//  for presentation only. Completion is persisted only when the user taps
//  Finish Setup.
//

import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var onboarding: OnboardingProgress
    @Bindable var appState: SpikeAppState
    @Environment(\.scenePhase) private var scenePhase
    @State private var safariEnablement = SafariExtensionEnablementModel()
    @State private var protectionTestStatus = SafariProtectionTestStore.displayStatus()
    /// Shared observable technical owner — not a view-local SWF snapshot.
    @State private var systemFiltering = SystemWebFilteringService.shared
    /// Ephemeral action/status copy only. Not live filter truth.
    @State private var systemFilterMessage: String?

    private enum VisibleStep: Equatable {
        case explanation
        case screenTimeAuthorization
        case safariExtensionEnablement
        case safariAllWebsitesConfirmation
        case safariPrivateBrowsingConfirmation
        case safariProtectionTest
        case systemWebFilteringConsent
        case finishSetup
    }

    private var visibleStep: VisibleStep {
        if !onboarding.hasAcknowledgedIntroduction {
            return .explanation
        }
        if !appState.isAuthorizationApproved {
            return .screenTimeAuthorization
        }
        if !safariEnablement.isEnabled {
            return .safariExtensionEnablement
        }
        if !onboarding.hasConfirmedSafariAllWebsitesAccess {
            return .safariAllWebsitesConfirmation
        }
        if !onboarding.hasConfirmedSafariPrivateBrowsing {
            return .safariPrivateBrowsingConfirmation
        }
        if protectionTestStatus != .passed {
            return .safariProtectionTest
        }
        if onboarding.systemWebFilteringDecision == nil {
            return .systemWebFilteringConsent
        }
        return .finishSetup
    }

    var body: some View {
        ScrollView {
            Group {
                switch visibleStep {
                case .explanation:
                    explanationStep
                case .screenTimeAuthorization:
                    screenTimeAuthorizationStep
                case .safariExtensionEnablement:
                    safariExtensionEnablementStep
                case .safariAllWebsitesConfirmation:
                    safariAllWebsitesConfirmationStep
                case .safariPrivateBrowsingConfirmation:
                    safariPrivateBrowsingConfirmationStep
                case .safariProtectionTest:
                    safariProtectionTestStep
                case .systemWebFilteringConsent:
                    systemWebFilteringConsentStep
                case .finishSetup:
                    finishSetupStep
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            appState.refreshAuthorizationStatus()
            refreshSafariExtensionStateIfNeeded()
            refreshProtectionTestStatusIfNeeded()
            refreshSystemFilterStateIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }
            refreshSafariExtensionStateIfNeeded()
            refreshProtectionTestStatusIfNeeded()
            refreshSystemFilterStateIfNeeded()
        }
        .onChange(of: visibleStep) { _, newStep in
            if newStep == .safariExtensionEnablement {
                safariEnablement.refresh()
                refreshSystemFilterState()
            }
            if newStep == .safariProtectionTest {
                refreshProtectionTestStatus()
            }
            if newStep == .systemWebFilteringConsent || newStep == .finishSetup {
                refreshSystemFilterState()
            }
        }
    }

    // MARK: - Step 0: Explanation

    private var explanationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("How Heal Works")
                .font(.largeTitle.bold())

            Text(
                "Heal interrupts access to selected apps or websites and guides "
                    + "you into a Safe Place instead."
            )
            .font(.body)

            Text(
                "You will configure protection in several guided steps. "
                    + "Screen Time access is required for Apple protection controls. "
                    + "Later steps will request Safari permissions separately."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            Button {
                onboarding.acknowledgeIntroduction()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            temporaryTestingControls
        }
    }

    // MARK: - Step 1: Screen Time authorization

    private var screenTimeAuthorizationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Screen Time Access")
                .font(.largeTitle.bold())

            Text(
                "Screen Time access is required so Heal can interrupt blocked apps "
                    + "or websites using Apple protection controls. Heal requests "
                    + "authorization for you as an individual — not a parent/child setup."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            ScreenTimeAuthorizationSection(appState: appState)

            temporaryTestingControls
        }
    }

    // MARK: - Step 2: Safari extension enablement

    private var safariExtensionEnablementStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Enable Safari Extension")
                .font(.largeTitle.bold())

            Text(
                "Heal’s Safari protection requires the Heal Safari extension to be "
                    + "turned on. Open Safari Extension Settings, enable Heal, then "
                    + "return here so Heal can detect the enabled state."
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
                            + "settings and block enabling the extension. Disable the "
                            + "filter here to recover, then enable the extension. This "
                            + "does not change your onboarding System Website Filtering "
                            + "decision."
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

            temporaryTestingControls
        }
    }

    // MARK: - Step 3: Manual All Websites confirmation

    private var safariAllWebsitesConfirmationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Allow on All Websites")
                .font(.largeTitle.bold())

            Text(
                "In Safari Extension Settings for Heal, grant access to "
                    + "“All Websites” (Always Allow on Every Website)."
            )
            .font(.body)

            Text(
                "Apple does not provide Heal an API to verify this setting. "
                    + "Confirm only after you have enabled All Websites access yourself."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            openSafariExtensionSettingsButton

            Button {
                onboarding.confirmSafariAllWebsitesAccess()
            } label: {
                Text("I enabled All Websites access")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            temporaryTestingControls
        }
    }

    // MARK: - Step 4: Manual Private Browsing confirmation

    private var safariPrivateBrowsingConfirmationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Allow in Private Browsing")
                .font(.largeTitle.bold())

            Text(
                "In Safari Extension Settings for Heal, enable "
                    + "“Allow in Private Browsing”."
            )
            .font(.body)

            Text(
                "Apple does not provide Heal an API to verify this setting. "
                    + "Confirm only after you have enabled Private Browsing access yourself."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            openSafariExtensionSettingsButton

            Button {
                onboarding.confirmSafariPrivateBrowsing()
            } label: {
                Text("I enabled Private Browsing access")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            temporaryTestingControls
        }
    }

    // MARK: - Step 5: Safari functional protection test

    private var safariProtectionTestStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Test Safari Protection")
                .font(.largeTitle.bold())

            Text(
                "Confirm that Heal’s Safari extension can interrupt the test page "
                    + "and return you through Safe Place. This proves the extension "
                    + "path works end to end."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            SafariProtectionTestSection(
                status: $protectionTestStatus,
                isStartEnabled: safariEnablement.isEnabled,
                refreshesWithLifecycle: false
            )

            temporaryTestingControls
        }
    }

    // MARK: - Step 6: Optional System Website Filtering consent

    private var systemWebFilteringConsentStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("System Website Filtering")
                .font(.largeTitle.bold())

            Text(
                "System Website Filtering is optional. It uses Apple’s system web "
                    + "content filter as an additional layer beyond the Safari extension. "
                    + "You can enable it now, skip it, or disable it later."
            )
            .font(.body)

            Text(
                "Warning: On tested devices, enabling System Website Filtering may "
                    + "grey out Safari extension settings. Finish Safari setup before "
                    + "enabling this filter. This is a device observation, not an "
                    + "Apple API guarantee."
            )
            .font(.body)
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

            Button {
                skipSystemWebsiteFiltering()
            } label: {
                Text("Skip for Now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if systemFiltering.filterState == .enabled {
                Button {
                    disableSystemWebsiteFiltering()
                } label: {
                    Text("Disable System Website Filtering")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            temporaryTestingControls
        }
    }

    // MARK: - Finish Setup

    private var finishSetupStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Finish Setup")
                .font(.largeTitle.bold())

            Text(
                "Your System Website Filtering choice is recorded. Tap Finish Setup "
                    + "to complete onboarding. Heal will only mark onboarding complete "
                    + "when you use this button — not automatically after Enable or Skip."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            Text(onboardingDecisionLabel)
                .font(.headline)

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

            if systemFiltering.filterState == .enabled {
                Button {
                    disableSystemWebsiteFiltering()
                } label: {
                    Text("Disable System Website Filtering")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Text("Safari extension status: Enabled")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("All Websites access: Confirmed by you")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Private Browsing access: Confirmed by you")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Functional protection test: Passed")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                onboarding.markOnboardingCompleted()
            } label: {
                Text("Finish Setup")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            temporaryTestingControls
        }
    }

    // MARK: - Shared controls

    private var openSafariExtensionSettingsButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let actionMessage = safariEnablement.actionMessage {
                Text(actionMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await safariEnablement.openSettings()
                }
            } label: {
                Text("Open Safari Extension Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(safariEnablement.isOpenSettingsUnavailable)
        }
    }

    private var temporaryTestingControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Text("Temporary testing controls")
                .font(.headline)

            Button {
                onboarding.resetTemporaryTestingState()
            } label: {
                Text("Reset Onboarding Progress (Temporary Test)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text(
                "Temporary test control only. Not part of the normal onboarding "
                    + "sequence. Reset clears OnboardingProgress flags "
                    + "(introduction acknowledgement, All Websites confirmation, "
                    + "Private Browsing confirmation, System Website Filtering "
                    + "decision, and completion). It does not change Screen Time "
                    + "authorization, disable the Safari extension, alter Safari "
                    + "system settings, alter functional-test state, or alter "
                    + "System Website Filtering. Use Finish Setup on the final "
                    + "step to persist completion for product testing."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
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

    // MARK: - Live Safari / functional-test / SWF refresh

    private func refreshSafariExtensionStateIfNeeded() {
        guard onboarding.hasAcknowledgedIntroduction else {
            return
        }
        guard appState.isAuthorizationApproved else {
            return
        }
        safariEnablement.refresh()
    }

    private func refreshProtectionTestStatusIfNeeded() {
        guard onboarding.hasAcknowledgedIntroduction else {
            return
        }
        guard appState.isAuthorizationApproved else {
            return
        }
        guard onboarding.hasConfirmedSafariAllWebsitesAccess else {
            return
        }
        guard onboarding.hasConfirmedSafariPrivateBrowsing else {
            return
        }
        refreshProtectionTestStatus()
    }

    private func refreshProtectionTestStatus() {
        protectionTestStatus = SafariProtectionTestStore.displayStatus()
    }

    private func refreshSystemFilterStateIfNeeded() {
        guard onboarding.hasAcknowledgedIntroduction else {
            return
        }
        guard appState.isAuthorizationApproved else {
            return
        }
        // Revalidate as soon as Screen Time is approved so the Safari enablement
        // step can offer recovery Disable when an active filter greys out settings.
        // Does not require M4 pass or an M5 decision. Read-only — no ManagedSettings write.
        refreshSystemFilterState()
    }

    private func refreshSystemFilterState() {
        systemFiltering.refreshFilterState()
        switch systemFiltering.filterState {
        case .enabled, .cleared:
            // Clear stale action messages after a successful live technical read.
            // Enable/Disable handlers may set an explicit message afterward.
            systemFilterMessage = nil
        case .error:
            break
        }
    }

    // MARK: - System Website Filtering actions

    private func enableSystemWebsiteFiltering() {
        systemFilterMessage = nil
        do {
            try systemFiltering.enableSystemWebsiteFiltering()
            guard systemFiltering.filterState == .enabled else {
                systemFilterMessage =
                    "Could not enable system website filtering: verification did not report enabled."
                return
            }
            onboarding.recordSystemWebFilteringEnabledDecision()
            systemFilterMessage = "System website filtering enabled."
        } catch {
            systemFilterMessage =
                "Could not enable system website filtering: \(error.localizedDescription)"
        }
    }

    private func skipSystemWebsiteFiltering() {
        systemFilterMessage = nil
        onboarding.recordSystemWebFilteringSkippedDecision()
    }

    private func disableSystemWebsiteFiltering() {
        systemFilterMessage = nil
        do {
            try systemFiltering.disableSystemWebsiteFiltering()
            guard systemFiltering.filterState == .cleared else {
                systemFilterMessage =
                    "Could not disable system website filtering: verification did not report cleared."
                return
            }
            systemFilterMessage = "System website filtering disabled."
        } catch {
            systemFilterMessage =
                "Could not disable system website filtering: \(error.localizedDescription)"
        }
    }
}

#Preview {
    OnboardingFlowView(onboarding: OnboardingProgress(), appState: SpikeAppState())
}
