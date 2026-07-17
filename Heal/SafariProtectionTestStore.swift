//
//  SafariProtectionTestStore.swift
//  Heal
//
//  App-only persistence for the Safari protection functional test attempt.
//  UserDefaults.standard is the single source of truth. Stateless wrapper —
//  no App Group, no shield handoff keys, no UUID (static block page returns
//  only the fixed source marker).
//

import Foundation

enum SafariProtectionTestStore {
    enum DisplayStatus: Equatable {
        case idle
        case waiting
        case passed
        case expired
    }

    private static let pendingStartedAtKey = "safariProtectionTest.pendingStartedAt"
    private static let passedAtKey = "safariProtectionTest.passedAt"
    private static let expiredAtKey = "safariProtectionTest.expiredAt"
    private static let validityWindow: TimeInterval = 5 * 60

    /// Current display status. Expires and clears stale pending attempts on read.
    static func displayStatus(now: Date = Date()) -> DisplayStatus {
        expirePendingIfNeeded(now: now)

        let defaults = UserDefaults.standard
        let pendingStartedAt = defaults.double(forKey: pendingStartedAtKey)
        if pendingStartedAt > 0,
           now.timeIntervalSince1970 - pendingStartedAt <= validityWindow {
            return .waiting
        }

        let expiredAt = defaults.double(forKey: expiredAtKey)
        let passedAt = defaults.double(forKey: passedAtKey)

        if expiredAt > 0, passedAt <= 0 || expiredAt >= passedAt {
            return .expired
        }

        if passedAt > 0 {
            return .passed
        }

        return .idle
    }

    /// Records a new pending attempt and clears any prior expired marker.
    static func startPending(now: Date = Date()) {
        let defaults = UserDefaults.standard
        defaults.set(now.timeIntervalSince1970, forKey: pendingStartedAtKey)
        defaults.removeObject(forKey: expiredAtKey)
    }

    /// Clears a pending attempt without recording pass or expiry (e.g. open failure).
    static func clearPending() {
        UserDefaults.standard.removeObject(forKey: pendingStartedAtKey)
    }

    /// Marks passed only when a non-expired pending attempt exists.
    /// Returns `true` when the pending attempt was accepted as a pass.
    @discardableResult
    static func markPassedIfPendingValid(now: Date = Date()) -> Bool {
        expirePendingIfNeeded(now: now)

        let defaults = UserDefaults.standard
        let pendingStartedAt = defaults.double(forKey: pendingStartedAtKey)
        guard pendingStartedAt > 0,
              now.timeIntervalSince1970 - pendingStartedAt <= validityWindow else {
            return false
        }

        defaults.removeObject(forKey: pendingStartedAtKey)
        defaults.removeObject(forKey: expiredAtKey)
        defaults.set(now.timeIntervalSince1970, forKey: passedAtKey)
        return true
    }

    private static func expirePendingIfNeeded(now: Date) {
        let defaults = UserDefaults.standard
        let pendingStartedAt = defaults.double(forKey: pendingStartedAtKey)
        guard pendingStartedAt > 0 else {
            return
        }

        guard now.timeIntervalSince1970 - pendingStartedAt > validityWindow else {
            return
        }

        defaults.removeObject(forKey: pendingStartedAtKey)
        defaults.set(now.timeIntervalSince1970, forKey: expiredAtKey)
    }
}
