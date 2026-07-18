//
//  SafariExtensionEnablementSection.swift
//  Heal
//
//  Shared Safari extension enablement presentation. Displays live state from
//  SafariExtensionEnablementModel and triggers refresh / open-settings.
//  Owns no persistence. Does not cover All Websites, Private Browsing,
//  or the functional Safari protection test.
//

import SwiftUI

struct SafariExtensionEnablementSection: View {
    @Bindable var model: SafariExtensionEnablementModel
    @Environment(\.scenePhase) private var scenePhase

    /// When true, refreshes on appear and when the app returns to the foreground.
    /// OnboardingFlowView may disable this and own foreground refresh itself so
    /// live state stays available for derived routing across later steps.
    var refreshesWithLifecycle: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safari Extension")
                .font(.headline)

            HStack(spacing: 8) {
                Text(stateLabel)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(stateColor)

                if showsProgressIndicator {
                    ProgressView()
                }
            }

            Text(
                "Turn on the Heal Safari extension in Safari Extension Settings, "
                    + "then return here. Heal can detect whether the extension is "
                    + "enabled."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("In Safari Extension Settings:")
                    .font(.subheadline.weight(.semibold))
                Text("1. Find the Heal extension.")
                Text("2. Turn the Heal extension on.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            if let actionMessage = model.actionMessage {
                Text(actionMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await model.openSettings()
                }
            } label: {
                Text("Open Safari Extension Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isOpenSettingsDisabled)
        }
        .onAppear {
            guard refreshesWithLifecycle else {
                return
            }
            model.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard refreshesWithLifecycle, newPhase == .active else {
                return
            }
            model.refresh()
        }
    }

    private var showsProgressIndicator: Bool {
        if case .checking = model.extensionState {
            return true
        }
        return model.isRefreshing
    }

    private var isOpenSettingsDisabled: Bool {
        if case .checking = model.extensionState {
            return true
        }
        return model.isOpenSettingsUnavailable
    }

    private var stateLabel: String {
        switch model.extensionState {
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
        switch model.extensionState {
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
}

#Preview {
    SafariExtensionEnablementSection(model: SafariExtensionEnablementModel())
        .padding()
}
