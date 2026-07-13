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
            .disabled(isRequestButtonDisabled)

            Spacer()
        }
        .padding()
        .onAppear {
            appState.refreshAuthorizationStatus()
        }
    }

    private var statusLabel: String {
        switch appState.authorizationStatus {
        case .notDetermined:
            return "Not determined"
        case .denied:
            return "Denied"
        case .approved:
            return "Approved"
        case .approvedWithDataAccess:
            return "Approved"
        default:
            return "Unknown"
        }
    }

    private var statusColor: Color {
        switch appState.authorizationStatus {
        case .notDetermined:
            return .orange
        case .denied:
            return .red
        case .approved:
            return .green
        case .approvedWithDataAccess:
            return .green
        default:
            return .secondary
        }
    }

    private var buttonTitle: String {
        switch appState.authorizationStatus {
        case .notDetermined:
            return "Enable Screen Time Access"
        case .denied:
            return "Try Requesting Access Again"
        case .approved:
            return "Screen Time Access Enabled"
        case .approvedWithDataAccess:
            return "Screen Time Access Enabled"
        default:
            return "Enable Screen Time Access"
        }
    }

    private var isRequestButtonDisabled: Bool {
        if appState.isRequestingAuthorization {
            return true
        }

        switch appState.authorizationStatus {
        case .notDetermined:
            return false
        case .denied:
            return false
        case .approved:
            return true
        case .approvedWithDataAccess:
            return true
        default:
            return false
        }
    }
}

#Preview {
    SetupView(appState: SpikeAppState())
}
