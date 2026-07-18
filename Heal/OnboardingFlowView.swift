//
//  OnboardingFlowView.swift
//  Heal
//
//  M2 onboarding shell: explanation + Screen Time authorization.
//  Visible step is derived from OnboardingProgress flags and live
//  SpikeAppState authorization status. Safari / SWF steps are not implemented.
//

import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var onboarding: OnboardingProgress
    @Bindable var appState: SpikeAppState

    private enum VisibleStep {
        case explanation
        case screenTimeAuthorization
        case m2Checkpoint
    }

    private var visibleStep: VisibleStep {
        if !onboarding.hasAcknowledgedIntroduction {
            return .explanation
        }
        if !appState.isAuthorizationApproved {
            return .screenTimeAuthorization
        }
        return .m2Checkpoint
    }

    var body: some View {
        ScrollView {
            Group {
                switch visibleStep {
                case .explanation:
                    explanationStep
                case .screenTimeAuthorization:
                    screenTimeAuthorizationStep
                case .m2Checkpoint:
                    m2CheckpointStep
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            appState.refreshAuthorizationStatus()
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

    // MARK: - Temporary M2 checkpoint

    private var m2CheckpointStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Screen Time Ready")
                .font(.largeTitle.bold())

            Text(
                "M2 checkpoint. Screen Time access is approved. "
                    + "Safari setup steps will be added next. "
                    + "Full onboarding is still incomplete."
            )
            .font(.body)
            .foregroundStyle(.secondary)

            Text("Authorization status: Approved")
                .font(.headline)

            temporaryTestingControls
        }
    }

    // MARK: - Temporary testing controls

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
                    + "(introduction acknowledgement and completion) and does not "
                    + "change Screen Time authorization. Mark Complete exits to the "
                    + "existing post-onboarding root for regression testing."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    OnboardingFlowView(onboarding: OnboardingProgress(), appState: SpikeAppState())
}
