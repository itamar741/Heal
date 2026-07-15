//
//  CoexistenceAutoFilterService.swift
//  Heal
//
//  Temporary spike: ManagedSettings webContent.blockedByFilter = .auto on a dedicated
//  named store alongside the Safari Web Extension.
//  Stage 2A: .auto with explicitly supplied example.com (does not prove classifier selection).
//  Stage 2B: .auto() classifier-only (empty additional domains).
//  Does not touch website-token shields, app shields, or the coexistenceSpecific store
//  except via caller-driven mutual exclusion.
//

import Foundation
import ManagedSettings

@MainActor
final class CoexistenceAutoFilterService {
    enum Mode: Equatable {
        case cleared
        case explicitDomain
        case classifierOnly
    }

    static let shared = CoexistenceAutoFilterService()

    static let storeName = ManagedSettingsStore.Name("coexistenceAuto")
    static let storeNameLabel = "coexistenceAuto"
    static let testDomain = "example.com"

    private let store = ManagedSettingsStore(named: storeName)
    private let testWebDomain = WebDomain(domain: testDomain)

    private init() {}

    /// Stage 2A: explicit harmless domain inside `.auto` (not classifier selection proof).
    func enableExplicitDomain() {
        store.webContent.blockedByFilter = .auto(
            [testWebDomain],
            except: []
        )
    }

    /// Stage 2B: classifier-only `.auto()` with no additionally blocked domains.
    func enableClassifierOnly() {
        store.webContent.blockedByFilter = .auto()
    }

    func clear() {
        store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.none
    }

    var mode: Mode {
        guard let policy = store.webContent.blockedByFilter else {
            return .cleared
        }

        switch policy {
        case .auto(let domains, _):
            if domains.contains(testWebDomain) {
                return .explicitDomain
            }
            if domains.isEmpty {
                return .classifierOnly
            }
            // Unexpected additional domains on this store — treat as inactive for UI.
            return .cleared
        case .none:
            return .cleared
        default:
            return .cleared
        }
    }

    var isActive: Bool {
        mode != .cleared
    }

    var isExplicitDomainActive: Bool {
        mode == .explicitDomain
    }

    var isClassifierOnlyActive: Bool {
        mode == .classifierOnly
    }
}
