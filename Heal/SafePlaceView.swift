//
//  SafePlaceView.swift
//  Heal
//
//  Slice 2: shield handoff → breathing / grounding → finite 14-Short vertical pager.
//  The “I feel better now” overlay belongs to a later slice.
//

import SwiftUI

private enum SafePlacePhase {
    case breathing
    case video
}

struct SafePlaceView: View {
    @Bindable var appState: SpikeAppState

    @State private var phase: SafePlacePhase = .breathing
    @State private var activeVideoIndex: Int?
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
                activeVideoIndex = 0
                embedLoadState = .loading
                embedRetryToken = 0
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
            videoChromeBar

            if embedLoadState == .failed {
                failureStrip
            }

            videoPager
        }
        .onChange(of: activeVideoIndex) { _, newIndex in
            guard newIndex != nil else { return }
            embedLoadState = .loading
        }
    }

    private var videoChromeBar: some View {
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
                Text("Exit Safe Place")
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
    }

    private var failureStrip: some View {
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

    private var videoPager: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(SafePlaceVideoCatalog.videoIDs.indices, id: \.self) { index in
                        videoPage(index: index)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $activeVideoIndex)
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private func videoPage(index: Int) -> some View {
        Color.black
            .overlay {
                if activeVideoIndex == index {
                    YouTubeEmbedWebView(
                        videoID: SafePlaceVideoCatalog.videoIDs[index],
                        loadState: $embedLoadState,
                        retryToken: embedRetryToken
                    )
                }
            }
    }
}

#Preview {
    SafePlaceView(appState: SpikeAppState())
}
