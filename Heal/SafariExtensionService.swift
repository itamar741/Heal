//
//  SafariExtensionService.swift
//  Heal
//
//  Product foundation: query Safari Web Extension enablement and open
//  Heal’s extension settings via public SafariServices APIs (iOS 26.2+).
//  Does not report All Websites access or Private Browsing configuration.
//

import Foundation
import SafariServices

@MainActor
final class SafariExtensionService {
    enum ExtensionState: Equatable {
        case checking
        case notFound
        case disabled
        case enabled
        case error(String)
    }

    static let shared = SafariExtensionService()

    /// Bundle identifier for the embedded Heal Safari Web Extension.
    static let extensionIdentifier = "com.itamar.Heal.HealSafariExtension"

    private(set) var currentState: ExtensionState = .checking

    private init() {}

    func refreshState() async {
        currentState = .checking
        currentState = await fetchState()
    }

    func openExtensionSettings() async throws {
        try await SFSafariSettings.openExtensionsSettings(
            forIdentifiers: [Self.extensionIdentifier]
        )
    }

    private func fetchState() async -> ExtensionState {
        await withCheckedContinuation { continuation in
            SFSafariExtensionManager.getStateOfExtension(
                withIdentifier: Self.extensionIdentifier
            ) { state, error in
                if let error {
                    continuation.resume(returning: .error(error.localizedDescription))
                    return
                }

                guard let state else {
                    continuation.resume(returning: .notFound)
                    return
                }

                continuation.resume(returning: state.isEnabled ? .enabled : .disabled)
            }
        }
    }
}
