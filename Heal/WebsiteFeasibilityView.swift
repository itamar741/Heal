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
    @State private var isCoexistenceFilterActive = false
    @State private var coexistenceStatusMessage: String?

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
                    Text("Specific coexistence test (temporary)")
                        .font(.headline)
                    Text(
                        isCoexistenceFilterActive
                            ? "Specific coexistence test active"
                            : "Specific coexistence test cleared"
                    )
                    .font(.title3.weight(.semibold))
                }

                if let coexistenceStatusMessage {
                    Text(coexistenceStatusMessage)
                        .font(.footnote)
                        .foregroundStyle(isCoexistenceFilterActive ? .green : .secondary)
                }

                Text("Named store: \(CoexistenceSpecificFilterService.storeNameLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    "Applies blockedByFilter = .specific for example.com only. "
                        + "Safari Web Extension rules stay unchanged. Does not use .auto. "
                        + "Clear website-token shields before this test. "
                        + "After clear, Safari may still redirect via the extension; verify clear in Chrome "
                        + "or temporarily disable the Safari extension."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Button {
                    enableCoexistenceFilter()
                } label: {
                    Text("Enable Specific Coexistence Test")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    clearCoexistenceFilter()
                } label: {
                    Text("Clear Specific Coexistence Test")
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

                Text(
                    "Apple’s automatic adult-content filter (blockedByFilter .auto) is not used here. "
                        + "The temporary specific coexistence control above is the only blockedByFilter path in this spike."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
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
            syncCoexistenceFilterStatus()
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

    private func enableCoexistenceFilter() {
        CoexistenceSpecificFilterService.shared.enable()
        syncCoexistenceFilterStatus()
        if isCoexistenceFilterActive {
            coexistenceStatusMessage = "Specific coexistence filter applied for example.com."
        } else {
            coexistenceStatusMessage = "Could not verify specific coexistence filter was applied."
        }
    }

    private func clearCoexistenceFilter() {
        CoexistenceSpecificFilterService.shared.clear()
        syncCoexistenceFilterStatus()
        if !isCoexistenceFilterActive {
            coexistenceStatusMessage =
                "Specific coexistence filter cleared (.none). "
                + "Safari may still redirect via the extension until it is disabled."
        } else {
            coexistenceStatusMessage = "Could not verify specific coexistence filter was cleared."
        }
    }

    private func syncCoexistenceFilterStatus() {
        isCoexistenceFilterActive = CoexistenceSpecificFilterService.shared.isActive
    }
}

#Preview {
    NavigationStack {
        WebsiteFeasibilityView()
    }
}
