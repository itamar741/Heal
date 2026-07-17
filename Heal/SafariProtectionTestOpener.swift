//
//  SafariProtectionTestOpener.swift
//  Heal
//
//  Opens the exact Safari protection test URL after recording a pending attempt.
//  Uses the system default URL handler (may be Safari or another browser).
//  Stateless — persistence stays in SafariProtectionTestStore.
//

import Foundation
import UIKit

@MainActor
enum SafariProtectionTestOpener {
    static let testURL = URL(string: "https://example.com/heal-safari-protection-test")!

    enum OpenError: LocalizedError {
        case couldNotOpenURL

        var errorDescription: String? {
            switch self {
            case .couldNotOpenURL:
                return "Could not open the Safari protection test URL."
            }
        }
    }

    /// Records a pending test, then opens the exact test URL with the system’s
    /// default URL handler. This is not guaranteed to open Safari.
    /// Clears the pending attempt if opening fails.
    static func startAndOpen() async throws {
        SafariProtectionTestStore.startPending()

        let opened = await UIApplication.shared.open(Self.testURL)
        guard opened else {
            SafariProtectionTestStore.clearPending()
            throw OpenError.couldNotOpenURL
        }
    }
}
