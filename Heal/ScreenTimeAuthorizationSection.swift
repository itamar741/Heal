//
//  ScreenTimeAuthorizationSection.swift
//  Heal
//
//  Shared Screen Time authorization presentation. Renders live status from
//  SpikeAppState and triggers requestAuthorization(). Owns no persistence.
//

import FamilyControls
import SwiftUI

struct ScreenTimeAuthorizationSection: View {
    @Bindable var appState: SpikeAppState

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
    ScreenTimeAuthorizationSection(appState: SpikeAppState())
        .padding()
}
