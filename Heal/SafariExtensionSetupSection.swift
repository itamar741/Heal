//
//  SafariExtensionSetupSection.swift
//  Heal
//
//  Minimal Safari Extension enablement UI for the setup flow.
//  Verifies only whether the extension is enabled — not All Websites
//  or Private Browsing configuration.
//  Also hosts the functional Safari protection test control; persisted
//  attempt/result state lives in SafariProtectionTestStore.
//

import SwiftUI

struct SafariExtensionSetupSection: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var extensionState: SafariExtensionService.ExtensionState = .checking
    @State private var functionalTestStatus: SafariProtectionTestStore.DisplayStatus = .idle
    @State private var actionMessage: String?
    @State private var functionalTestActionMessage: String?
    // Local ownership is enough while this section owns only local display state.
    // If Safari extension status later joins a shared multi-step onboarding flow,
    // move that flow state into a dedicated onboarding model/coordinator and keep
    // SafariExtensionService stateless and injectable — not shared mutable state.
    private let service = SafariExtensionService()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safari Extension")
                .font(.headline)

            HStack(spacing: 8) {
                Text(stateLabel)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(stateColor)

                if extensionState == .checking {
                    ProgressView()
                }
            }

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
                Text("In Safari Extension Settings:")
                    .font(.subheadline.weight(.semibold))
                Text("1. Turn on the Heal extension.")
                Text("2. Select Always Allow for Every Website.")
                Text("3. Enable the extension for Private Browsing.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            if let actionMessage {
                Text(actionMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await openSettings()
                }
            } label: {
                Text("Open Safari Extension Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(extensionState == .checking)

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
            .disabled(extensionState != .enabled)
        }
        .onAppear {
            Task {
                await refresh()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await refresh()
            }
        }
    }

    private var stateLabel: String {
        switch extensionState {
        case .checking:
            return "Status: checking"
        case .notFound:
            return "Status: not found"
        case .disabled:
            return "Status: disabled"
        case .enabled:
            return "Status: enabled"
        case .error:
            return "Status: error"
        }
    }

    private var stateColor: Color {
        switch extensionState {
        case .checking:
            return .secondary
        case .notFound:
            return .orange
        case .disabled:
            return .orange
        case .enabled:
            return .green
        case .error:
            return .red
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

    private func refresh() async {
        extensionState = .checking
        let state = await service.fetchState()
        extensionState = state
        refreshFunctionalTestStatus()

        if case .error(let message) = state {
            actionMessage = message
        } else {
            actionMessage = nil
        }
    }

    private func openSettings() async {
        do {
            try await service.openExtensionSettings()
            actionMessage = "Opened Safari Extension Settings. Enable the extension, then return here."
        } catch {
            actionMessage = "Could not open Safari Extension Settings: \(error.localizedDescription)"
        }
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
