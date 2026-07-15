//
//  CoexistenceAutoFilterService.swift
//  Heal
//
//  Temporary Stage 2A spike: apply ManagedSettings webContent.blockedByFilter = .auto
//  with an explicitly supplied example.com domain on a dedicated named store,
//  alongside the Safari Web Extension. Does not prove Apple classifier selection.
//  Does not touch website-token shields, app shields, or the coexistenceSpecific store
//  except via caller-driven mutual exclusion.
//

import Foundation
import ManagedSettings

@MainActor
final class CoexistenceAutoFilterService {
    static let shared = CoexistenceAutoFilterService()

    static let storeName = ManagedSettingsStore.Name("coexistenceAuto")
    static let storeNameLabel = "coexistenceAuto"
    static let testDomain = "example.com"

    private let store = ManagedSettingsStore(named: storeName)
    private let testWebDomain = WebDomain(domain: testDomain)

    private init() {}

    func enable() {
        store.webContent.blockedByFilter = .auto(
            [testWebDomain],
            except: []
        )
    }

    func clear() {
        store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.none
    }

    var isActive: Bool {
        guard let policy = store.webContent.blockedByFilter else {
            return false
        }

        if case .auto(let domains, _) = policy {
            return domains.contains(testWebDomain)
        }

        return false
    }
}
