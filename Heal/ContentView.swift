//
//  ContentView.swift
//  Heal
//
//  Created by USER on 07/07/2026.
//

import SwiftUI

struct ContentView: View {
    @Bindable var appState: SpikeAppState
    @Bindable var onboarding: OnboardingProgress
    @Bindable var repairSession: ProtectionRepairSession

    var body: some View {
        if !appState.hasRefreshedSystemState {
            ProgressView("Checking Screen Time access...")
                .padding()
        } else if appState.pendingSafePlaceEntry {
            SafePlaceView(appState: appState)
        } else if !onboarding.hasCompletedOnboarding {
            OnboardingFlowView(onboarding: onboarding, appState: appState)
        } else if !repairSession.hasDeferredRepairThisSession {
            // Completed users: evaluate live repair issues unless deferred
            // for this app process only. Host shows repair or post-onboarding.
            ProtectionRepairHost(
                appState: appState,
                onboarding: onboarding,
                repairSession: repairSession
            )
        } else {
            PostOnboardingRootView(appState: appState)
        }
    }
}

/// Shared post-onboarding presentation only. No persistence or service ownership.
/// Used by the deferred-session path and by ProtectionRepairHost when healthy.
struct PostOnboardingRootView: View {
    @Bindable var appState: SpikeAppState

    var body: some View {
        if appState.isAuthorizationApproved {
            AppSelectionView(appState: appState)
        } else {
            SetupView(appState: appState)
        }
    }
}

#Preview {
    ContentView(
        appState: SpikeAppState(),
        onboarding: OnboardingProgress(),
        repairSession: ProtectionRepairSession()
    )
}
