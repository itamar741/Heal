//
//  SafePlaceView.swift
//  Heal
//
//  Slice 1: shield handoff → breathing / grounding → one YouTube Short inside Heal.
//  Vertical paging and the “I feel better now” overlay belong to later slices.
//

import SwiftUI

private enum SafePlacePhase {
    case breathing
    case video
}

struct SafePlaceView: View {
    @Bindable var appState: SpikeAppState

    @State private var phase: SafePlacePhase = .breathing
    @State private var embedLoadState: YouTubeEmbedLoadState = .loading
    @State private var embedRetryToken = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch phase {
            case .breathing:
                breathingScreen
            case .video:
                videoScreen
            }
        }
        .onAppear {
            appState.consumeHandoffMarkerAfterPresentation()
        }
    }

    // MARK: - Breathing

    private var breathingScreen: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("Safe Place")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            Text("Breathe in slowly.\nHold for a moment.\nBreathe out.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .lineSpacing(6)

            Spacer()

            Button {
                phase = .video
                embedLoadState = .loading
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.92))
            .foregroundStyle(.black)
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Video

    private var videoScreen: some View {
        VStack(spacing: 0) {
            // Temporary Slice 1 exit — dedicated area above the player (Slice 4 replacement).
            HStack {
                if embedLoadState == .loading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }

                Spacer()

                Button {
                    appState.dismissSafePlaceEntry()
                } label: {
                    Text("Exit (Slice 1 temp)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.55))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if embedLoadState == .failed {
                VStack(spacing: 12) {
                    Text("Couldn’t load the video.\nCheck your connection and try again.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))

                    Button("Retry") {
                        embedLoadState = .loading
                        embedRetryToken += 1
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.92))
                    .foregroundStyle(.black)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }

            // Player sits below the dedicated chrome; no native UI overlays the iframe.
            YouTubeEmbedWebView(
                videoID: SafePlaceVideoCatalog.slice1VideoID,
                loadState: $embedLoadState,
                retryToken: embedRetryToken
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SafePlaceView(appState: SpikeAppState())
}
