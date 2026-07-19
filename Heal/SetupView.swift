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
                Text("Heal")
                    .font(.largeTitle.bold())

                Text("Screen Time access is required so Heal can interrupt a blocked app and guide you into a Safe Place. Grant or restore authorization for yourself as an individual — not a parent/child setup.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                ScreenTimeAuthorizationSection(appState: appState)

                #if DEBUG
                Divider()

                SafariExtensionSetupSection()
                #endif
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
