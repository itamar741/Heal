//
//  AppSelectionView.swift
//  Heal
//

import FamilyControls
import SwiftUI

struct AppSelectionView: View {
    @Bindable var appState: SpikeAppState
    @State private var isPickerPresented = false

    var body: some View {
        NavigationStack {
            appSelectionContent
        }
    }

    private var appSelectionContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            NavigationLink {
                WebsiteFeasibilityView()
            } label: {
                Text("Website Feasibility (Stage 1)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("Choose One App")
                .font(.largeTitle.bold())

            Text("For this spike, select exactly one app. Categories, web domains, and multiple apps are not accepted yet.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Selection status")
                    .font(.headline)
                Text(appState.hasPersistedAppSelection ? "One app selected" : "No app selected")
                    .font(.title3.weight(.semibold))
            }

            if let selectionValidationMessage = appState.selectionValidationMessage {
                Text(selectionValidationMessage)
                    .font(.footnote)
                    .foregroundStyle(appState.hasPersistedAppSelection ? .green : .red)
            }

            Button {
                isPickerPresented = true
            } label: {
                Text("Open App Picker")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                appState.validateAndPersistSelectedApp()
            } label: {
                Text("Save One-App Selection")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Shield status")
                    .font(.headline)
                Text(appState.isShieldApplied ? "Shield applied" : "Shield not applied")
                    .font(.title3.weight(.semibold))
            }

            if let shieldStatusMessage = appState.shieldStatusMessage {
                Text(shieldStatusMessage)
                    .font(.footnote)
                    .foregroundStyle(appState.isShieldApplied ? .green : .secondary)
            }

            Button {
                appState.applyShieldToPersistedSelection()
            } label: {
                Text("Apply Shield")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!appState.hasPersistedAppSelection)

            Button {
                appState.clearShield()
            } label: {
                Text("Clear Shield")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Handoff marker")
                    .font(.headline)
                Text(appState.handoffStatusMessage)
                    .font(.footnote)
                    .foregroundStyle(appState.detectedHandoffSessionID == nil ? Color.secondary : Color.green)

                if let detectedHandoffSessionID = appState.detectedHandoffSessionID {
                    Text("Session: \(detectedHandoffSessionID)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let detectedHandoffCreatedAt = appState.detectedHandoffCreatedAt {
                    Text("Created: \(detectedHandoffCreatedAt.formatted(date: .omitted, time: .standard))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                appState.refreshHandoffDebugStatus()
            } label: {
                Text("Refresh Handoff Status")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $appState.activitySelection
        )
        .onAppear {
            appState.reloadPersistedSelection()
        }
    }
}

#Preview {
    AppSelectionView(appState: SpikeAppState())
}
