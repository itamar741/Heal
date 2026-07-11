//
//  ContentView.swift
//  Heal
//
//  Created by USER on 07/07/2026.
//

import SwiftUI

struct ContentView: View {
    @Bindable var appState: SpikeAppState

    var body: some View {
        SetupView(appState: appState)
    }
}

#Preview {
    ContentView(appState: SpikeAppState())
}
