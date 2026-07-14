//
//  HandoffWriter.swift
//  HealShieldAction
//

import Foundation

enum HandoffWriter {
    enum HandoffError: LocalizedError {
        case appGroupUnavailable

        var errorDescription: String? {
            switch self {
            case .appGroupUnavailable:
                return "App Group storage is unavailable."
            }
        }
    }

    private static let appGroupID = "group.com.itamar.Heal"
    private static let pendingKey = "pendingSafePlaceLaunch"
    private static let createdAtKey = "createdAt"
    private static let triggerKindKey = "triggerKind"
    private static let sessionIdKey = "sessionId"

    static func writePendingAppHandoff() throws {
        try writePendingHandoff(triggerKind: "app")
    }

    static func writePendingWebsiteHandoff() throws {
        try writePendingHandoff(triggerKind: "webDomain")
    }

    private static func writePendingHandoff(triggerKind: String) throws {
        let defaults = try sharedDefaults()
        defaults.set(true, forKey: pendingKey)
        defaults.set(Date().timeIntervalSince1970, forKey: createdAtKey)
        defaults.set(triggerKind, forKey: triggerKindKey)
        defaults.set(UUID().uuidString, forKey: sessionIdKey)
    }

    private static func sharedDefaults() throws -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            throw HandoffError.appGroupUnavailable
        }

        return defaults
    }
}
