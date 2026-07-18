//
//  SafariExtensionSetupSection.swift
//  Heal
//
//  Minimal Safari Extension setup UI for the spike/setup flow.
//  Reuses SafariExtensionEnablementSection for enablement query/open-settings
//  and SafariProtectionTestSection for the functional protection test.
//  Persisted attempt/result state lives in SafariProtectionTestStore.
//

import SwiftUI

struct SafariExtensionSetupSection: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var enablement = SafariExtensionEnablementModel()
    @State private var functionalTestStatus: SafariProtectionTestStore.DisplayStatus = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SafariExtensionEnablementSection(
                model: enablement,
                refreshesWithLifecycle: false
            )

            Text(
                "Heal can verify only whether the Safari extension is enabled. "
                    + "Always Allow on Every Website and Private Browsing must be set manually — "
                    + "Heal cannot detect those settings."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text(
                "Complete Safari extension setup (enable, Always Allow on Every Website, "
                    + "and Private Browsing) before enabling System Website Filtering."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Also in Safari Extension Settings:")
                    .font(.subheadline.weight(.semibold))
                Text("1. Select Always Allow for Every Website.")
                Text("2. Enable the extension for Private Browsing.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Divider()

            SafariProtectionTestSection(
                status: $functionalTestStatus,
                isStartEnabled: enablement.isEnabled,
                refreshesWithLifecycle: false
            )
        }
        .onAppear {
            enablement.refresh()
            functionalTestStatus = SafariProtectionTestStore.displayStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            enablement.refresh()
            functionalTestStatus = SafariProtectionTestStore.displayStatus()
        }
    }
}

#Preview {
    SafariExtensionSetupSection()
        .padding()
}
