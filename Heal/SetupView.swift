//
//  SetupView.swift
//  Heal
//

import SwiftUI

struct SetupView: View {
    @Bindable var appState: SpikeAppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Heal Spike")
                    .font(.largeTitle.bold())

                Text("Screen Time access is required so Heal can interrupt a blocked app and guide you into a Safe Place. This spike only requests authorization for you as an individual — not a parent/child setup.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                ScreenTimeAuthorizationSection(appState: appState)

                Divider()

                SafariExtensionSetupSection()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            appState.refreshAuthorizationStatus()
        }
    }
}

#Preview {
    SetupView(appState: SpikeAppState())
}
