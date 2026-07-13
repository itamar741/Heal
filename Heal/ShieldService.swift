//
//  ShieldService.swift
//  Heal
//

import FamilyControls
import Foundation
import ManagedSettings

@MainActor
final class ShieldService {
    enum ShieldError: LocalizedError {
        case missingSelection
        case invalidSelection

        var errorDescription: String? {
            switch self {
            case .missingSelection:
                return "No saved app selection found. Save one app before applying a shield."
            case .invalidSelection:
                return "Saved selection is invalid. Save exactly one app before applying a shield."
            }
        }
    }

    static let shared = ShieldService()

    private let store = ManagedSettingsStore()

    private init() {}

    func applyShieldToPersistedSelection() throws {
        guard let selection = try SelectionPersistence.loadSelectedAppSelection() else {
            throw ShieldError.missingSelection
        }

        guard selection.applicationTokens.count == 1,
              selection.categoryTokens.isEmpty,
              selection.webDomainTokens.isEmpty
        else {
            throw ShieldError.invalidSelection
        }

        store.shield.applications = selection.applicationTokens
    }

    func clearShield() {
        store.shield.applications = nil
    }

    /// True only when the persisted one-app token is present in the store's shield applications.
    func isPersistedSelectionShielded() throws -> Bool {
        guard let selection = try SelectionPersistence.loadSelectedAppSelection() else {
            return false
        }

        guard selection.applicationTokens.count == 1,
              selection.categoryTokens.isEmpty,
              selection.webDomainTokens.isEmpty,
              let persistedToken = selection.applicationTokens.first
        else {
            return false
        }

        guard let shieldedApplications = store.shield.applications else {
            return false
        }

        return shieldedApplications.contains(persistedToken)
    }
}
