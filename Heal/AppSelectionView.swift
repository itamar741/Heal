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
        VStack(alignment: .leading, spacing: 24) {
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
