//
//  SafariExtensionEnablementModel.swift
//  Heal
//
//  Narrowly scoped presentation model for live Safari extension enablement
//  display and open-settings actions. Keeps SafariExtensionService as the
//  technical owner; holds only ephemeral UI state. Does not persist enablement.
//

import Foundation
import Observation

@Observable
@MainActor
final class SafariExtensionEnablementModel {
    /// Matches Apple’s observed Safari Extensions Settings limit:
    /// maximum 2 calls per rolling 60-second window.
    private static let openSettingsWindowSeconds: TimeInterval = 60
    private static let openSettingsWindowLimit = 2

    private let service: SafariExtensionService
    private var refreshTask: Task<Void, Never>?
    private var openSettingsWindowWakeTask: Task<Void, Never>?

    /// Ephemeral timestamps of open-settings attempts that reached the service
    /// (newest last). Blocked / ignored taps are not recorded.
    private var openSettingsAttemptTimestamps: [Date] = []
    /// Conservative block used only when a rate-limit error is caught.
    private var rateLimitBlockedUntil: Date?

    private(set) var extensionState: SafariExtensionService.ExtensionState = .checking
    private(set) var isRefreshing = false
    private(set) var actionMessage: String?
    private(set) var isOpenSettingsRequestInProgress = false
    /// True when the rolling attempt window is full or a rate-limit recovery
    /// block is active.
    private(set) var isOpenSettingsWindowLimited = false

    var isEnabled: Bool {
        extensionState == .enabled
    }

    /// True while a request is in flight or the rolling window / recovery block
    /// currently prevents another open-settings call.
    var isOpenSettingsUnavailable: Bool {
        isOpenSettingsRequestInProgress || isOpenSettingsWindowLimited
    }

    init(service: SafariExtensionService? = nil) {
        self.service = service ?? SafariExtensionService()
    }

    /// Fetches live enablement. Cancels any in-flight refresh so appear and
    /// foreground triggers do not overlap. Does not write persistence.
    /// Keeps the last known non-checking state while refreshing so derived
    /// onboarding routing does not flash away from later steps.
    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            isRefreshing = true

            let state = await service.fetchState()
            guard !Task.isCancelled else {
                return
            }

            extensionState = state
            isRefreshing = false

            if case .error(let message) = state {
                actionMessage = message
            } else {
                actionMessage = nil
            }
        }
    }

    func openSettings() async {
        refreshOpenSettingsWindowAvailability()
        guard !isOpenSettingsUnavailable else {
            return
        }

        isOpenSettingsRequestInProgress = true
        defer {
            isOpenSettingsRequestInProgress = false
        }

        // Record the attempt immediately before the service call so any request
        // that reaches Apple counts against the rolling window, including
        // ordinary failures. Ignored / blocked taps never reach this point.
        recordOpenSettingsAttempt()

        do {
            try await service.openExtensionSettings()
            actionMessage = "Opened Safari Extension Settings. Enable the extension, then return here."
        } catch {
            if Self.isRateLimitError(error) {
                // Attempt already recorded. Do not present the raw API text.
                actionMessage =
                    "Safari Extension Settings were opened recently. Try again in about a minute."
                beginConservativeRateLimitRecovery()
                return
            }

            // Attempt already recorded; genuine error is still surfaced.
            actionMessage = "Could not open Safari Extension Settings: \(error.localizedDescription)"
        }
    }

    private func recordOpenSettingsAttempt() {
        pruneOpenSettingsWindow()
        openSettingsAttemptTimestamps.append(Date())
        refreshOpenSettingsWindowAvailability()
    }

    private func beginConservativeRateLimitRecovery() {
        rateLimitBlockedUntil = Date().addingTimeInterval(Self.openSettingsWindowSeconds)
        refreshOpenSettingsWindowAvailability()
    }

    private func refreshOpenSettingsWindowAvailability() {
        pruneOpenSettingsWindow()
        let limitedByWindow = openSettingsAttemptTimestamps.count >= Self.openSettingsWindowLimit
        let limitedByRateLimitRecovery = rateLimitBlockedUntil.map { Date() < $0 } ?? false
        isOpenSettingsWindowLimited = limitedByWindow || limitedByRateLimitRecovery
        scheduleOpenSettingsWindowWakeIfNeeded()
    }

    private func pruneOpenSettingsWindow() {
        let cutoff = Date().addingTimeInterval(-Self.openSettingsWindowSeconds)
        openSettingsAttemptTimestamps.removeAll { $0 <= cutoff }

        if let rateLimitBlockedUntil, Date() >= rateLimitBlockedUntil {
            self.rateLimitBlockedUntil = nil
        }
    }

    private func scheduleOpenSettingsWindowWakeIfNeeded() {
        openSettingsWindowWakeTask?.cancel()
        openSettingsWindowWakeTask = nil

        guard isOpenSettingsWindowLimited else {
            return
        }

        var wakeAt: Date?
        if openSettingsAttemptTimestamps.count >= Self.openSettingsWindowLimit,
           let oldest = openSettingsAttemptTimestamps.first {
            wakeAt = oldest.addingTimeInterval(Self.openSettingsWindowSeconds)
        }
        if let rateLimitBlockedUntil {
            if let currentWakeAt = wakeAt {
                wakeAt = min(currentWakeAt, rateLimitBlockedUntil)
            } else {
                wakeAt = rateLimitBlockedUntil
            }
        }

        guard let wakeAt else {
            return
        }

        let delay = wakeAt.timeIntervalSinceNow
        guard delay > 0 else {
            refreshOpenSettingsWindowAvailability()
            return
        }

        openSettingsWindowWakeTask = Task {
            let nanoseconds = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else {
                return
            }
            refreshOpenSettingsWindowAvailability()
        }
    }

    private static func isRateLimitError(_ error: Error) -> Bool {
        error.localizedDescription.localizedCaseInsensitiveContains("rate limit")
    }
}
