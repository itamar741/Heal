//
//  SelectionPersistence.swift
//  Heal
//

import FamilyControls
import Foundation

enum SelectionPersistence {
    enum PersistenceError: LocalizedError {
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .verificationFailed:
                return "The selected app was written but could not be verified."
            }
        }
    }

    private static let fileName = "selected-app-selection.json"

    static func loadSelectedAppSelection() throws -> FamilyActivitySelection? {
        let url = try selectionFileURL()

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    static func saveSelectedAppSelection(_ selection: FamilyActivitySelection) throws {
        let data = try JSONEncoder().encode(selection)
        let url = try selectionFileURL()

        try data.write(to: url, options: [.atomic])

        guard let verifiedSelection = try loadSelectedAppSelection(),
              verifiedSelection.applicationTokens.count == 1,
              verifiedSelection.categoryTokens.isEmpty,
              verifiedSelection.webDomainTokens.isEmpty
        else {
            throw PersistenceError.verificationFailed
        }
    }

    static func clearSelectedAppSelection() throws {
        let url = try selectionFileURL()

        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        try FileManager.default.removeItem(at: url)
    }

    private static func selectionFileURL() throws -> URL {
        let directoryURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return directoryURL.appendingPathComponent(fileName)
    }
}
