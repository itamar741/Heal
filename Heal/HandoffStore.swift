//
//  HandoffStore.swift
//  Heal
//

import Foundation

enum HandoffStore {
    enum HandoffError: LocalizedError {
        case appGroupUnavailable

        var errorDescription: String? {
            switch self {
            case .appGroupUnavailable:
                return "App Group storage is unavailable."
            }
        }
    }

    struct Marker {
        let pendingSafePlaceLaunch: Bool
        let createdAt: TimeInterval
        let triggerKind: String
        let sessionId: String

        var isRecent: Bool {
            Date().timeIntervalSince1970 - createdAt <= validityWindow
        }
    }

    private static let appGroupID = "group.com.itamar.Heal"
    private static let pendingKey = "pendingSafePlaceLaunch"
    private static let createdAtKey = "createdAt"
    private static let triggerKindKey = "triggerKind"
    private static let sessionIdKey = "sessionId"
    private static let validityWindow: TimeInterval = 5 * 60

    static func readMarker() throws -> Marker? {
        let defaults = try sharedDefaults()
        let pending = defaults.bool(forKey: pendingKey)

        guard pending else {
            return nil
        }

        let createdAt = defaults.double(forKey: createdAtKey)
        let triggerKind = defaults.string(forKey: triggerKindKey) ?? "unknown"
        let sessionId = defaults.string(forKey: sessionIdKey) ?? ""
        let marker = Marker(
            pendingSafePlaceLaunch: pending,
            createdAt: createdAt,
            triggerKind: triggerKind,
            sessionId: sessionId
        )

        guard marker.isRecent else {
            return nil
        }

        return marker
    }

    static func consumeMarker() throws {
        let defaults = try sharedDefaults()
        defaults.removeObject(forKey: pendingKey)
        defaults.removeObject(forKey: createdAtKey)
        defaults.removeObject(forKey: triggerKindKey)
        defaults.removeObject(forKey: sessionIdKey)
    }

    private static func sharedDefaults() throws -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            throw HandoffError.appGroupUnavailable
        }

        return defaults
    }
}
