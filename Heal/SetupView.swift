//
//  SetupView.swift
//  Heal
//

import FamilyControls
import SwiftUI

struct SetupView: View {
    @Bindable var appState: SpikeAppState

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Heal Spike")
                .font(.largeTitle.bold())

            Text("Screen Time access is required so Heal can interrupt a blocked app and guide you into a Safe Place. This spike only requests authorization for you as an individual — not a parent/child setup.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Authorization status")
                    .font(.headline)
                Text(statusLabel)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(statusColor)
            }

            if let lastErrorMessage = appState.lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    await appState.requestAuthorization()
                }
            } label: {
                if appState.isRequestingAuthorization {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(buttonTitle)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.isRequestingAuthorization || appState.authorizationStatus == .approved)

            Spacer()
        }
        .padding()
        .onAppear {
            appState.refreshAuthorizationStatus()
        }
    }

    private var statusLabel: String {
        if appState.authorizationStatus == .approved {
            return "Approved"
        }

        if appState.authorizationStatus == .denied {
            return "Denied"
        }

        if appState.authorizationStatus == .notDetermined {
            return "Not determined"
        }

        return "Unknown"
    }

    private var statusColor: Color {
        if appState.authorizationStatus == .approved {
            return .green
        }

        if appState.authorizationStatus == .denied {
            return .red
        }

        if appState.authorizationStatus == .notDetermined {
            return .orange
        }

        return .secondary
    }

    private var buttonTitle: String {
        if appState.authorizationStatus == .approved {
            return "Screen Time Access Enabled"
        }

        if appState.authorizationStatus == .denied {
            return "Try Requesting Access Again"
        }

        return "Enable Screen Time Access"
    }
}

#Preview {
    SetupView(appState: SpikeAppState())
}
