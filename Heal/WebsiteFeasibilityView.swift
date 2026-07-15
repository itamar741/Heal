//
//  WebsiteFeasibilityView.swift
//  Heal
//
//  Stage 1 website feasibility: select one WebDomainToken, apply named-store shield,
//  and validate custom shield → handoff → Safe Place plumbing in Safari.
//  Not final product UI. No adult-content classification in this stage.
//

import FamilyControls
import SwiftUI

struct WebsiteFeasibilityView: View {
    @State private var websiteSelection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var validationMessage: String?
    @State private var hasValidSelection = false
    @State private var isWebsiteShieldApplied = false
    @State private var shieldStatusMessage: String?
    @State private var systemFilterState: SystemWebFilteringService.FilterState = .cleared
    @State private var systemFilterMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Website Feasibility (Stage 1)")
                    .font(.largeTitle.bold())

                Text(
                    "Technical test only. Select exactly one website domain, apply the website shield, "
                    + "then open that site in Safari. This does not prove adult-content classification."
                )
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Selection status")
                        .font(.headline)
                    Text(hasValidSelection ? "One website domain selected" : "No valid website selection")
                        .font(.title3.weight(.semibold))
                }

                if let validationMessage {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(hasValidSelection ? .green : .red)
                }

                Button {
                    isPickerPresented = true
                } label: {
                    Text("Open Website Picker")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    validateSelection()
                } label: {
                    Text("Validate One-Domain Selection")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Website shield status")
                        .font(.headline)
                    Text(isWebsiteShieldApplied ? "Website shield applied" : "Website shield not applied")
                        .font(.title3.weight(.semibold))
                }

                if let shieldStatusMessage {
                    Text(shieldStatusMessage)
                        .font(.footnote)
                        .foregroundStyle(isWebsiteShieldApplied ? .green : .secondary)
                }

                Text("Named store: \(WebsiteShieldService.storeNameLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    applyWebsiteShield()
                } label: {
                    Text("Apply Website Shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasValidSelection)

                Button {
                    clearWebsiteShield()
                } label: {
                    Text("Clear Website Shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Safari test")
                        .font(.headline)
                    Text(
                        "After applying, open the selected domain in Safari. "
                        + "Expect the custom Heal shield, then Open Safe Place."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("System Website Filtering")
                        .font(.headline)
                    Text(systemFilterStateLabel)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(systemFilterStateColor)
                }

                if let systemFilterMessage {
                    Text(systemFilterMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button {
                    enableSystemWebsiteFiltering()
                } label: {
                    Text("Enable System Website Filtering")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    disableSystemWebsiteFiltering()
                } label: {
                    Text("Disable System Website Filtering")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Website Feasibility")
        .navigationBarTitleDisplayMode(.inline)
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $websiteSelection
        )
        .onAppear {
            syncWebsiteShieldStatus()
            syncSystemFilterStatus()
        }
    }

    private var systemFilterStateLabel: String {
        switch systemFilterState {
        case .enabled:
            return "Current state: enabled"
        case .cleared:
            return "Current state: cleared"
        case .error:
            return "Current state: error"
        }
    }

    private var systemFilterStateColor: Color {
        switch systemFilterState {
        case .enabled:
            return .green
        case .cleared:
            return .secondary
        case .error:
            return .red
        }
    }

    private func validateSelection() {
        let applicationCount = websiteSelection.applicationTokens.count
        let categoryCount = websiteSelection.categoryTokens.count
        let webDomainCount = websiteSelection.webDomainTokens.count

        if applicationCount > 0 {
            hasValidSelection = false
            validationMessage = "Application tokens are rejected. Select one website domain only."
            return
        }

        if categoryCount > 0 {
            hasValidSelection = false
            validationMessage = "Category tokens are rejected. Select one website domain only."
            return
        }

        if webDomainCount == 0 {
            hasValidSelection = false
            validationMessage = "Select one website domain before validating."
            return
        }

        if webDomainCount > 1 {
            hasValidSelection = false
            validationMessage = "Select exactly one website domain. Multiple domains are not accepted."
            return
        }

        hasValidSelection = true
        validationMessage = "One website domain selected for this session."
        syncWebsiteShieldStatus()
    }

    private func applyWebsiteShield() {
        guard hasValidSelection else {
            shieldStatusMessage = "Validate a one-domain selection first."
            return
        }

        do {
            try WebsiteShieldService.shared.applyShield(to: websiteSelection)
            syncWebsiteShieldStatus()
            if isWebsiteShieldApplied {
                shieldStatusMessage = "Website shield applied on named store."
            } else {
                shieldStatusMessage = "Could not verify website shield was applied."
            }
        } catch {
            syncWebsiteShieldStatus()
            shieldStatusMessage = "Could not apply website shield: \(error.localizedDescription)"
        }
    }

    private func clearWebsiteShield() {
        WebsiteShieldService.shared.clearShield()
        syncWebsiteShieldStatus()
        if !isWebsiteShieldApplied {
            shieldStatusMessage = "Website shield cleared on named store."
        } else {
            shieldStatusMessage = "Could not verify website shield was cleared."
        }
    }

    private func syncWebsiteShieldStatus() {
        guard hasValidSelection else {
            isWebsiteShieldApplied = false
            return
        }

        do {
            isWebsiteShieldApplied = try WebsiteShieldService.shared.isSelectionShielded(websiteSelection)
        } catch {
            isWebsiteShieldApplied = false
            shieldStatusMessage = "Could not read website shield status: \(error.localizedDescription)"
        }
    }

    private func enableSystemWebsiteFiltering() {
        do {
            try SystemWebFilteringService.shared.enableSystemWebsiteFiltering()
            syncSystemFilterStatus()
            systemFilterMessage = "System website filtering enabled."
        } catch {
            syncSystemFilterStatus()
            systemFilterMessage = "Could not enable system website filtering: \(error.localizedDescription)"
        }
    }

    private func disableSystemWebsiteFiltering() {
        do {
            try SystemWebFilteringService.shared.disableSystemWebsiteFiltering()
            syncSystemFilterStatus()
            systemFilterMessage = "System website filtering disabled."
        } catch {
            syncSystemFilterStatus()
            systemFilterMessage = "Could not disable system website filtering: \(error.localizedDescription)"
        }
    }

    private func syncSystemFilterStatus() {
        systemFilterState = SystemWebFilteringService.shared.currentState
        if case .error(let message) = systemFilterState {
            systemFilterMessage = message
        }
    }
}

#Preview {
    NavigationStack {
        WebsiteFeasibilityView()
    }
}
