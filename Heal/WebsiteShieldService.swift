//
//  WebsiteShieldService.swift
//  Heal
//
//  Stage 1 website feasibility: shield one picker-selected WebDomainToken
//  on a separate named ManagedSettingsStore. Does not touch the default app shield.
//

import FamilyControls
import Foundation
import ManagedSettings

@MainActor
final class WebsiteShieldService {
    enum WebsiteShieldError: LocalizedError {
        case invalidSelection

        var errorDescription: String? {
            switch self {
            case .invalidSelection:
                return "Select exactly one website domain with no apps or categories."
            }
        }
    }

    static let shared = WebsiteShieldService()

    /// Separate from the default store used by the one-app spike shield.
    static let storeName = ManagedSettingsStore.Name("websiteFeasibility")
    static let storeNameLabel = "websiteFeasibility"

    private let store = ManagedSettingsStore(named: storeName)

    private init() {}

    func applyShield(to selection: FamilyActivitySelection) throws {
        guard isValidWebsiteFeasibilitySelection(selection),
              let domainToken = selection.webDomainTokens.first else {
            throw WebsiteShieldError.invalidSelection
        }

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
        store.shield.webDomains = [domainToken]
    }

    func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
        store.shield.webDomains = nil
    }

    func isSelectionShielded(_ selection: FamilyActivitySelection) throws -> Bool {
        guard isValidWebsiteFeasibilitySelection(selection),
              let domainToken = selection.webDomainTokens.first else {
            return false
        }

        guard let shieldedDomains = store.shield.webDomains else {
            return false
        }

        return shieldedDomains.contains(domainToken)
    }

    func isValidWebsiteFeasibilitySelection(_ selection: FamilyActivitySelection) -> Bool {
        selection.webDomainTokens.count == 1
            && selection.applicationTokens.isEmpty
            && selection.categoryTokens.isEmpty
    }
}
