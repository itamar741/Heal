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

    var body: some View {
        if !appState.hasRefreshedSystemState {
            ProgressView("Checking Screen Time access...")
                .padding()
        } else if appState.pendingSafePlaceEntry {
            SafePlaceView(appState: appState)
        } else if !onboarding.hasCompletedOnboarding {
            OnboardingFlowView(onboarding: onboarding, appState: appState)
        } else if appState.isAuthorizationApproved {
            AppSelectionView(appState: appState)
        } else {
            SetupView(appState: appState)
        }
    }
}

#Preview {
    ContentView(appState: SpikeAppState(), onboarding: OnboardingProgress())
}
