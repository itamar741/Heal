//
//  HealApp.swift
//  Heal
//
//  Created by USER on 07/07/2026.
//

import SwiftUI

@main
struct HealApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState = SpikeAppState()
    @State private var onboarding = OnboardingProgress()
    /// Process-scoped only. Survives Safe Place / root switches; not persisted.
    @State private var protectionRepairSession = ProtectionRepairSession()

    var body: some Scene {
        WindowGroup {
            ContentView(
                appState: appState,
                onboarding: onboarding,
                repairSession: protectionRepairSession
            )
                .task {
                    appState.refreshSystemState()
                    appState.evaluatePendingSafePlaceEntry()
                }
                .onChange(of: scenePhase) { _, newScenePhase in
                    guard newScenePhase == .active else {
                        return
                    }

                    appState.refreshSystemState()
                    appState.evaluatePendingSafePlaceEntry()
                }
                .onOpenURL { url in
                    appState.handleIncomingURL(url)
                }
        }
    }
}
