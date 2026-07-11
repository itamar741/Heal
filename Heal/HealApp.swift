//
//  HealApp.swift
//  Heal
//
//  Created by USER on 07/07/2026.
//

import SwiftUI

@main
struct HealApp: App {
    @State private var appState = SpikeAppState()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
        }
    }
}
