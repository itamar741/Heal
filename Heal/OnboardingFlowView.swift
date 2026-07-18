//
//  OnboardingFlowView.swift
//  Heal
//
//  M3 onboarding shell: explanation, Screen Time, Safari enablement, and
//  manual All Websites / Private Browsing confirmations.
//  Visible step is derived from OnboardingProgress flags, live SpikeAppState
//  authorization, and live Safari extension enablement. Functional Safari
//  protection test (M4) and System Website Filtering (M5) are not implemented.
//

import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var onboarding: OnboardingProgress
    @Bindable var appState: SpikeAppState
    @Environment(\.scenePhase) private var scenePhase
    @State private var safariEnablement = SafariExtensionEnablementModel()

    private enum VisibleStep: Equatable {
        case explanation
        case screenTimeAuthorization
        case safariExtensionEnablement
        case safariAllWebsitesConfirmation
        case safariPrivateBrowsingConfirmation
        case m3Checkpoint
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
        return .m3Checkpoint
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
                case .m3Checkpoint:
                    m3CheckpointStep
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            appState.refreshAuthorizationStatus()
            refreshSafariExtensionStateIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }
            refreshSafariExtensionStateIfNeeded()
        }
        .onChange(of: visibleStep) { _, newStep in
            if newStep == .safariExtensionEnablement {
                safariEnablement.refresh()
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

    // MARK: - Temporary M3 checkpoint

    private var m3CheckpointStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Safari Setup Ready")
                .font(.largeTitle.bold())

            Text(
                "M3 checkpoint. Safari extension setup prerequisites are satisfied. "
                    + "The functional Safari protection test will be added in M4. "
                    + "Full onboarding is still incomplete."
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

    // MARK: - Live Safari refresh

    private func refreshSafariExtensionStateIfNeeded() {
        guard onboarding.hasAcknowledgedIntroduction else {
            return
        }
        guard appState.isAuthorizationApproved else {
            return
        }
        safariEnablement.refresh()
    }
}

#Preview {
    OnboardingFlowView(onboarding: OnboardingProgress(), appState: SpikeAppState())
}
