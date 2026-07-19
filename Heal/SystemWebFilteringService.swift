//
//  SystemWebFilteringService.swift
//  Heal
//
//  Product foundation: enable/disable Apple’s automatic system website filtering
//  via Managed Settings on a dedicated named store. Single observable owner of
//  live filter presentation state. Does not touch app shields, token-based
//  website shields, or the Safari Web Extension.
//

import FamilyControls
import Foundation
import ManagedSettings
import Observation

@Observable
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

    /// Shared observable live filter state. Initialized from ManagedSettings — never assumed `.cleared`.
    private(set) var filterState: FilterState

    /// Compatibility alias for the same stored observable value — not an independent read.
    var currentState: FilterState { filterState }

    private init() {
        do {
            filterState = try Self.readFilterState(from: store)
        } catch {
            filterState = .error(error.localizedDescription)
        }
    }

    /// Re-reads ManagedSettings and publishes the result. Use for appear/foreground revalidation.
    func refreshFilterState() {
        do {
            filterState = try Self.readFilterState(from: store)
        } catch {
            filterState = .error(error.localizedDescription)
        }
    }

    func enableSystemWebsiteFiltering() throws {
        var writeError: Error?
        do {
            try requireAuthorization()
            store.webContent.blockedByFilter = .auto()
        } catch {
            writeError = error
        }

        // Always publish post-attempt live state before returning or throwing.
        refreshFilterState()

        if let writeError {
            throw writeError
        }

        guard filterState == .enabled else {
            throw SystemWebFilteringError.verificationFailed(
                "System website filtering was set but could not be verified as enabled."
            )
        }
    }

    func disableSystemWebsiteFiltering() throws {
        var writeError: Error?
        do {
            try requireAuthorization()
            store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.none
        } catch {
            writeError = error
        }

        // Always publish post-attempt live state before returning or throwing.
        refreshFilterState()

        if let writeError {
            throw writeError
        }

        guard filterState == .cleared else {
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

    private static func readFilterState(from store: ManagedSettingsStore) throws -> FilterState {
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
