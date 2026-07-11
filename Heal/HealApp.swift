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

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .task {
                    appState.refreshSystemState()
                }
                .onChange(of: scenePhase) { _, newScenePhase in
                    guard newScenePhase == .active else {
                        return
                    }

                    appState.refreshSystemState()
                }
        }
    }
}
