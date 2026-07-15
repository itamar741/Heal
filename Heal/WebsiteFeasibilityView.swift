//
//  WebsiteFeasibilityView.swift
//  Heal
//
//  Stage 1 website feasibility: select one WebDomainToken, apply named-store shield,
//  and validate custom shield → handoff → Safe Place plumbing in Safari.
//  Temporary coexistence controls also live here (specific + auto Stage 2A/2B).
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
    @State private var autoCoexistenceMode: CoexistenceAutoFilterService.Mode = .cleared
    @State private var autoCoexistenceStatusMessage: String?

    private var isAutoCoexistenceFilterActive: Bool {
        autoCoexistenceMode != .cleared
    }

    private var autoModeStatusLabel: String {
        switch autoCoexistenceMode {
        case .cleared:
            return "Auto coexistence cleared"
        case .explicitDomain:
            return "Explicit-domain Auto active (Stage 2A)"
        case .classifierOnly:
            return "Classifier-only Auto active (Stage 2B)"
        }
    }

    private var autoSummaryLabel: String {
        switch autoCoexistenceMode {
        case .cleared:
            return "cleared"
        case .explicitDomain:
            return "explicit-domain active"
        case .classifierOnly:
            return "classifier-only active"
        }
    }

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
                    Text("Coexistence store summary (temporary)")
                        .font(.headline)
                    Text(
                        "Specific (\(CoexistenceSpecificFilterService.storeNameLabel)): "
                            + (isCoexistenceFilterActive ? "active" : "cleared")
                    )
                    .font(.subheadline.weight(.semibold))
                    Text(
                        "Auto (\(CoexistenceAutoFilterService.storeNameLabel)): "
                            + autoSummaryLabel
                    )
                    .font(.subheadline.weight(.semibold))
                }

                Text(
                    "Enabling Specific clears Auto. Enabling either Auto mode clears Specific "
                        + "and replaces the other Auto mode on the same store. "
                        + "Neither touches websiteFeasibility or the default app-shield store."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

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
                        + "Safari Web Extension rules stay unchanged. "
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
                    Text("Auto coexistence tests (temporary)")
                        .font(.headline)
                    Text(autoModeStatusLabel)
                        .font(.title3.weight(.semibold))
                }

                if let autoCoexistenceStatusMessage {
                    Text(autoCoexistenceStatusMessage)
                        .font(.footnote)
                        .foregroundStyle(isAutoCoexistenceFilterActive ? .green : .secondary)
                }

                Text("Named store: \(CoexistenceAutoFilterService.storeNameLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    "Stage 2A — Auto with explicit harmless domain: blockedByFilter = .auto([example.com], except: []). "
                        + "Does not prove Apple’s adult-content classifier selected the domain."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Button {
                    enableExplicitDomainAutoFilter()
                } label: {
                    Text("Enable Auto Explicit-Domain Test")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Text(
                    "Stage 2B — Auto classifier-only: blockedByFilter = .auto() with no additional domains. "
                        + "Requires a domain Apple’s classifier already blocks, plus a temporary local Safari rule "
                        + "for that hostname (never commit the hostname)."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Button {
                    enableClassifierOnlyAutoFilter()
                } label: {
                    Text("Enable Auto Classifier-Only Test")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    clearAutoCoexistenceFilter()
                } label: {
                    Text("Clear Auto Test")
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
                    "Temporary coexistence controls above use dedicated named stores only. "
                        + "Classifier-selected domain coexistence requires Stage 2B device evidence."
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
            syncAutoCoexistenceFilterStatus()
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
        let clearedAuto = CoexistenceAutoFilterService.shared.isActive
        CoexistenceAutoFilterService.shared.clear()
        CoexistenceSpecificFilterService.shared.enable()
        syncCoexistenceFilterStatus()
        syncAutoCoexistenceFilterStatus()
        if isCoexistenceFilterActive {
            coexistenceStatusMessage = clearedAuto
                ? "Specific coexistence filter applied for example.com. Cleared coexistenceAuto first."
                : "Specific coexistence filter applied for example.com."
            autoCoexistenceStatusMessage = clearedAuto
                ? "Auto coexistence filter cleared (.none) for mutual exclusion."
                : autoCoexistenceStatusMessage
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

    private func enableExplicitDomainAutoFilter() {
        let clearedSpecific = CoexistenceSpecificFilterService.shared.isActive
        let previousMode = CoexistenceAutoFilterService.shared.mode
        CoexistenceSpecificFilterService.shared.clear()
        CoexistenceAutoFilterService.shared.enableExplicitDomain()
        syncCoexistenceFilterStatus()
        syncAutoCoexistenceFilterStatus()
        if autoCoexistenceMode == .explicitDomain {
            var message = "Explicit-domain Auto applied (.auto with example.com)."
            if clearedSpecific {
                message += " Cleared coexistenceSpecific first."
            }
            if previousMode == .classifierOnly {
                message += " Replaced classifier-only Auto on the same store."
            }
            autoCoexistenceStatusMessage = message
            if clearedSpecific {
                coexistenceStatusMessage = "Specific coexistence filter cleared (.none) for mutual exclusion."
            }
        } else {
            autoCoexistenceStatusMessage = "Could not verify explicit-domain Auto was applied."
        }
    }

    private func enableClassifierOnlyAutoFilter() {
        let clearedSpecific = CoexistenceSpecificFilterService.shared.isActive
        let previousMode = CoexistenceAutoFilterService.shared.mode
        CoexistenceSpecificFilterService.shared.clear()
        CoexistenceAutoFilterService.shared.enableClassifierOnly()
        syncCoexistenceFilterStatus()
        syncAutoCoexistenceFilterStatus()
        if autoCoexistenceMode == .classifierOnly {
            var message = "Classifier-only Auto applied (.auto() with no additional domains)."
            if clearedSpecific {
                message += " Cleared coexistenceSpecific first."
            }
            if previousMode == .explicitDomain {
                message += " Replaced explicit-domain Auto on the same store."
            }
            autoCoexistenceStatusMessage = message
            if clearedSpecific {
                coexistenceStatusMessage = "Specific coexistence filter cleared (.none) for mutual exclusion."
            }
        } else {
            autoCoexistenceStatusMessage = "Could not verify classifier-only Auto was applied."
        }
    }

    private func clearAutoCoexistenceFilter() {
        CoexistenceAutoFilterService.shared.clear()
        syncAutoCoexistenceFilterStatus()
        if autoCoexistenceMode == .cleared {
            autoCoexistenceStatusMessage =
                "Auto coexistence filter cleared (.none). "
                + "Safari may still redirect via the extension until it is disabled."
        } else {
            autoCoexistenceStatusMessage = "Could not verify Auto coexistence filter was cleared."
        }
    }

    private func syncAutoCoexistenceFilterStatus() {
        autoCoexistenceMode = CoexistenceAutoFilterService.shared.mode
    }
}

#Preview {
    NavigationStack {
        WebsiteFeasibilityView()
    }
}
