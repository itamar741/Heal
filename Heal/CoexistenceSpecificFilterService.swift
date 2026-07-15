//
//  CoexistenceSpecificFilterService.swift
//  Heal
//
//  Temporary spike: apply ManagedSettings webContent.blockedByFilter = .specific
//  for example.com on a dedicated named store, alongside the Safari Web Extension.
//  Does not touch website-token shields, app shields, or .auto filtering.
//

import Foundation
import ManagedSettings

@MainActor
final class CoexistenceSpecificFilterService {
    static let shared = CoexistenceSpecificFilterService()

    static let storeName = ManagedSettingsStore.Name("coexistenceSpecific")
    static let storeNameLabel = "coexistenceSpecific"
    static let testDomain = "example.com"

    private let store = ManagedSettingsStore(named: storeName)
    private let testWebDomain = WebDomain(domain: testDomain)

    private init() {}

    func enable() {
        store.webContent.blockedByFilter = .specific([testWebDomain])
    }

    func clear() {
        store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.none
    }

    var isActive: Bool {
        guard let policy = store.webContent.blockedByFilter else {
            return false
        }

        if case .specific(let domains) = policy {
            return domains.contains(testWebDomain)
        }

        return false
    }
}
