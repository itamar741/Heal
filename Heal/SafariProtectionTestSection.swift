//
//  SafariProtectionTestSection.swift
//  Heal
//
//  Shared Safari protection functional-test presentation. Displays status from
//  SafariProtectionTestStore and starts attempts via SafariProtectionTestOpener.
//  Owns no persistence. Pass marking remains in SpikeAppState URL handling.
//

import SwiftUI

struct SafariProtectionTestSection: View {
    @Binding var status: SafariProtectionTestStore.DisplayStatus
    @Environment(\.scenePhase) private var scenePhase
    @State private var actionMessage: String?
    @State private var isStarting = false

    /// When false, the start control is disabled (e.g. extension not enabled).
    var isStartEnabled: Bool = true

    /// When true, refreshes status on appear and foreground.
    var refreshesWithLifecycle: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Functional test")
                .font(.subheadline.weight(.semibold))

            Text(statusLabel)
                .font(.footnote)
                .foregroundStyle(statusColor)

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

            if status == .waiting {
                Text(SafariProtectionTestOpener.testURL.absoluteString)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .foregroundStyle(.primary)
            }

            if let actionMessage {
                Text(actionMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    await startFunctionalTest()
                }
            } label: {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isStartEnabled || isStarting || status == .waiting)
        }
        .onAppear {
            guard refreshesWithLifecycle else {
                return
            }
            refreshStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard refreshesWithLifecycle, newPhase == .active else {
                return
            }
            refreshStatus()
        }
    }

    private var buttonTitle: String {
        if isStarting {
            return "Opening Test…"
        }

        switch status {
        case .idle:
            return "Test Safari Protection"
        case .waiting:
            return "Waiting for Safari Return"
        case .passed:
            return "Test Safari Protection Again"
        case .expired:
            return "Retry Safari Protection Test"
        }
    }

    private var statusLabel: String {
        switch status {
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

    private var statusColor: Color {
        switch status {
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

    private func refreshStatus() {
        status = SafariProtectionTestStore.displayStatus()
    }

    private func startFunctionalTest() async {
        guard !isStarting, status != .waiting, isStartEnabled else {
            return
        }

        isStarting = true
        actionMessage = nil
        defer { isStarting = false }

        do {
            try await SafariProtectionTestOpener.startAndOpen()
            refreshStatus()
        } catch {
            refreshStatus()
            actionMessage = error.localizedDescription
        }
    }
}

#Preview {
    SafariProtectionTestSection(
        status: .constant(.idle)
    )
    .padding()
}
