//
//  SystemWebFilteringService.swift
//  Heal
//
//  Product foundation: enable/disable Apple’s automatic system website filtering
//  via Managed Settings on a dedicated named store. Does not touch app shields,
//  token-based website shields, or the Safari Web Extension.
//

import FamilyControls
import Foundation
import ManagedSettings

@MainActor
final class SystemWebFilteringService {
    enum FilterState: Equatable {
        case enabled
        case cleared
        case error(String)
    }

    enum SystemWebFilteringError: LocalizedError {
        case notAuthorized
        case verificationFailed(String)

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Family Controls authorization is required before changing system website filtering."
            case .verificationFailed(let detail):
                return detail
            }
        }
    }

    static let shared = SystemWebFilteringService()

    /// Dedicated product store — not the default app-shield store or websiteFeasibility.
    static let storeName = ManagedSettingsStore.Name("systemWebFiltering")
    static let storeNameLabel = "systemWebFiltering"

    private let store = ManagedSettingsStore(named: storeName)

    private init() {}

    var currentState: FilterState {
        do {
            return try readFilterState()
        } catch {
            return .error(error.localizedDescription)
        }
    }

    func enableSystemWebsiteFiltering() throws {
        try requireAuthorization()
        store.webContent.blockedByFilter = .auto()

        let state = try readFilterState()
        guard state == .enabled else {
            throw SystemWebFilteringError.verificationFailed(
                "System website filtering was set but could not be verified as enabled."
            )
        }
    }

    func disableSystemWebsiteFiltering() throws {
        try requireAuthorization()
        store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.none

        let state = try readFilterState()
        guard state == .cleared else {
            throw SystemWebFilteringError.verificationFailed(
                "System website filtering was cleared but could not be verified as cleared."
            )
        }
    }

    private func requireAuthorization() throws {
        guard AuthorizationService.status == .approved else {
            throw SystemWebFilteringError.notAuthorized
        }
    }

    private func readFilterState() throws -> FilterState {
        guard let policy = store.webContent.blockedByFilter else {
            return .cleared
        }
        if case .none = policy {
            return .cleared
        }
        // Dedicated store: any non-none policy means this product filter is active.
        return .enabled
    }
}
