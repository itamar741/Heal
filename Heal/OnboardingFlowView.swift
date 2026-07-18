//
//  OnboardingFlowView.swift
//  Heal
//
//  M4 onboarding shell: explanation, Screen Time, Safari enablement, manual
//  All Websites / Private Browsing confirmations, and the Safari functional
//  protection test. Visible step is derived from OnboardingProgress flags,
//  live SpikeAppState authorization, live Safari extension enablement, and
//  SafariProtectionTestStore status. System Website Filtering (M5) is not
//  implemented. Full onboarding completion is not set by a test pass.
//

import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var onboarding: OnboardingProgress
    @Bindable var appState: SpikeAppState
    @Environment(\.scenePhase) private var scenePhase
    @State private var safariEnablement = SafariExtensionEnablementModel()
    @State private var protectionTestStatus = SafariProtectionTestStore.displayStatus()

    private enum VisibleStep: Equatable {
        case explanation
        case screenTimeAuthorization
        case safariExtensionEnablement
        case safariAllWebsitesConfirmation
        case safariPrivateBrowsingConfirmation
        case safariProtectionTest
        case m4Checkpoint
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
        return .m4Checkpoint
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
                case .m4Checkpoint:
                    m4CheckpointStep
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            appState.refreshAuthorizationStatus()
            refreshSafariExtensionStateIfNeeded()
            refreshProtectionTestStatusIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }
            refreshSafariExtensionStateIfNeeded()
            refreshProtectionTestStatusIfNeeded()
        }
        .onChange(of: visibleStep) { _, newStep in
            if newStep == .safariExtensionEnablement {
                safariEnablement.refresh()
            }
            if newStep == .safariProtectionTest {
                refreshProtectionTestStatus()
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

    // MARK: - Temporary M4 checkpoint

    private var m4CheckpointStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Safari Protection Test Passed")
                .font(.largeTitle.bold())

            Text(
                "M4 checkpoint. The Safari functional protection test passed. "
                    + "Optional System Website Filtering consent will be added in M5. "
                    + "Full onboarding is still incomplete. A past pass does not prove "
                    + "Safari protection is still configured right now."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            Text("Safari extension status: Enabled")
                .font(.headline)

            Text("All Websites access: Confirmed by you")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Private Browsing access: Confirmed by you")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Functional protection test: Passed")
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
                onboarding.markOnboardingCompleted()
            } label: {
                Text("Mark Onboarding Complete (Temporary Test)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                onboarding.resetTemporaryTestingState()
            } label: {
                Text("Reset Onboarding Progress (Temporary Test)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text(
                "Temporary test controls only. Not part of the normal onboarding "
                    + "sequence. Reset clears OnboardingProgress flags "
                    + "(introduction acknowledgement, All Websites confirmation, "
                    + "Private Browsing confirmation, and completion). It does not "
                    + "change Screen Time authorization, disable the Safari extension, "
                    + "alter Safari system settings, alter functional-test state, or "
                    + "alter System Website Filtering. Mark Complete exits to the "
                    + "existing post-onboarding root for regression testing."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Live Safari / functional-test refresh

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
}

#Preview {
    OnboardingFlowView(onboarding: OnboardingProgress(), appState: SpikeAppState())
}
