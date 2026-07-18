//
//  SafariExtensionSetupSection.swift
//  Heal
//
//  Minimal Safari Extension setup UI for the spike/setup flow.
//  Reuses SafariExtensionEnablementSection for enablement query/open-settings.
//  Also hosts the functional Safari protection test control; persisted
//  attempt/result state lives in SafariProtectionTestStore.
//

import SwiftUI

struct SafariExtensionSetupSection: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var enablement = SafariExtensionEnablementModel()
    @State private var functionalTestStatus: SafariProtectionTestStore.DisplayStatus = .idle
    @State private var functionalTestActionMessage: String?

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

            Text("Functional test")
                .font(.subheadline.weight(.semibold))

            Text(functionalTestStatusLabel)
                .font(.footnote)
                .foregroundStyle(functionalTestStatusColor)

            Text(
                "Heal opens the test link in your default browser. "
                    + "The functional test can pass only when you complete that URL in Safari, "
                    + "where Heal’s Safari extension runs. "
                    + "If another browser opens, return here and open the same test URL "
                    + "manually in Safari within the five-minute test window. "
                    + "A past pass means the test succeeded earlier — "
                    + "it does not prove Safari protection is still configured right now."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            if functionalTestStatus == .waiting {
                Text(SafariProtectionTestOpener.testURL.absoluteString)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .foregroundStyle(.primary)
            }

            if let functionalTestActionMessage {
                Text(functionalTestActionMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    await startFunctionalTest()
                }
            } label: {
                Text("Test Safari Protection")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!enablement.isEnabled)
        }
        .onAppear {
            enablement.refresh()
            refreshFunctionalTestStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            enablement.refresh()
            refreshFunctionalTestStatus()
        }
    }

    private var functionalTestStatusLabel: String {
        switch functionalTestStatus {
        case .idle:
            return "Functional test: not tested"
        case .waiting:
            return "Functional test: waiting for Safari return"
        case .passed:
            return "Functional test: passed previously"
        case .expired:
            return "Functional test: test expired"
        }
    }

    private var functionalTestStatusColor: Color {
        switch functionalTestStatus {
        case .idle:
            return .secondary
        case .waiting:
            return .orange
        case .passed:
            return .green
        case .expired:
            return .orange
        }
    }

    private func refreshFunctionalTestStatus() {
        functionalTestStatus = SafariProtectionTestStore.displayStatus()
    }

    private func startFunctionalTest() async {
        functionalTestActionMessage = nil

        do {
            try await SafariProtectionTestOpener.startAndOpen()
            refreshFunctionalTestStatus()
        } catch {
            refreshFunctionalTestStatus()
            functionalTestActionMessage = error.localizedDescription
        }
    }
}

#Preview {
    SafariExtensionSetupSection()
        .padding()
}
