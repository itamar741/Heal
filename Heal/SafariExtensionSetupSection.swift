//
//  SafariExtensionSetupSection.swift
//  Heal
//
//  Minimal Safari Extension enablement UI for the setup flow.
//  Verifies only whether the extension is enabled — not All Websites
//  or Private Browsing configuration.
//

import SwiftUI

struct SafariExtensionSetupSection: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var extensionState: SafariExtensionService.ExtensionState = .checking
    @State private var actionMessage: String?
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

    private func refresh() async {
        extensionState = .checking
        let state = await service.fetchState()
        extensionState = state

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
}

#Preview {
    SafariExtensionSetupSection()
        .padding()
}
