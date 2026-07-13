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

// Spike-only outcome labels for local logging. Not persisted or shared app-wide.
private enum SafePlaceOutcome: String {
    case urgePassed = "The urge passed"
    case anotherVideo = "Show me another video"
    case needHelp = "I still need help"
    case close = "Close"
}

struct SafePlaceView: View {
    @Bindable var appState: SpikeAppState

    // Spike-only local state. Outcomes are not stored in SpikeAppState.
    @State private var recordedOutcomes: [SafePlaceOutcome] = []
    @State private var anotherVideoFeedbackMessage: String?

    var body: some View {
        ScrollView {
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

                videoPlaceholder

                outcomeButtons

                if let anotherVideoFeedbackMessage {
                    Text(anotherVideoFeedbackMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let handoffConsumptionMessage = appState.handoffConsumptionMessage {
                    Text(handoffConsumptionMessage)
                        .font(.footnote)
                        .foregroundColor(
                            handoffConsumptionMessage.contains("Could not") ? Color.red : Color.secondary
                        )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            appState.consumeHandoffMarkerAfterPresentation()
        }
    }

    // Spike-only static placeholder. No AVPlayer, asset, or feed behavior.
    private var videoPlaceholder: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemFill))
                    .aspectRatio(16 / 9, contentMode: .fit)

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            }

            Text("Supportive video placeholder")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var outcomeButtons: some View {
        VStack(spacing: 12) {
            outcomeButton(.urgePassed, prominent: true)
            outcomeButton(.anotherVideo, prominent: false)
            outcomeButton(.needHelp, prominent: false)
            outcomeButton(.close, prominent: false)
        }
    }

    @ViewBuilder
    private func outcomeButton(_ outcome: SafePlaceOutcome, prominent: Bool) -> some View {
        if prominent {
            Button {
                handleOutcome(outcome)
            } label: {
                Text(outcome.rawValue)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                handleOutcome(outcome)
            } label: {
                Text(outcome.rawValue)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func handleOutcome(_ outcome: SafePlaceOutcome) {
        recordedOutcomes.append(outcome)
        let sessionId = appState.launchContext.sessionId ?? "none"
        print("[SafePlace] outcome=\(outcome.rawValue) session=\(sessionId) count=\(recordedOutcomes.count)")

        switch outcome {
        case .urgePassed, .needHelp:
            break
        case .anotherVideo:
            anotherVideoFeedbackMessage = "Another video requested (spike: same placeholder)."
        case .close:
            appState.dismissSafePlaceEntry()
        }
    }
}

#Preview {
    SafePlaceView(appState: SpikeAppState())
}
