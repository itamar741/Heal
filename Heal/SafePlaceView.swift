//
//  SafePlaceView.swift
//  Heal
//
//  Spike-only placeholder for the Safe Place entry experience.
//  This is not final product architecture. The same surface may later become
//  a home feed, Reels-style experience, dedicated intervention screen, or
//  shared content with a different entry context.
//

import SwiftUI

struct SafePlaceView: View {
    @Bindable var appState: SpikeAppState

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Safe Place")
                .font(.largeTitle.bold())

            Text("Take a breath. You chose to pause before opening that app.")
                .foregroundStyle(.secondary)

            if appState.launchContext.openedFromShieldHandoff {
                Text("Opened from shield handoff")
                    .font(.headline)

                if let sessionId = appState.launchContext.sessionId {
                    Text("Session: \(sessionId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let createdAt = appState.launchContext.createdAt {
                    Text("Created: \(createdAt.formatted(date: .omitted, time: .standard))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let handoffConsumptionMessage = appState.handoffConsumptionMessage {
                Text(handoffConsumptionMessage)
                    .font(.footnote)
                    .foregroundStyle(handoffConsumptionMessage.contains("Could not") ? .red : .secondary)
            }

            Button {
                appState.dismissSafePlaceEntry()
            } label: {
                Text("Back to app")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .onAppear {
            appState.consumeHandoffMarkerAfterPresentation()
        }
    }
}

#Preview {
    SafePlaceView(appState: SpikeAppState())
}
