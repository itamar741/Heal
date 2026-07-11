//
//  SpikeAppState.swift
//  Heal
//

import FamilyControls
import Foundation
import Observation

@Observable
@MainActor
final class SpikeAppState {
    var authorizationStatus: AuthorizationStatus = AuthorizationService.status
    var lastErrorMessage: String?

    var isRequestingAuthorization = false
    var activitySelection = FamilyActivitySelection()
    var selectionValidationMessage: String?
    var hasPersistedAppSelection = false
    var hasRefreshedSystemState = false
    var isRefreshingSystemState = false

    init() {
        reloadPersistedSelection()
    }

    var isAuthorizationApproved: Bool {
        authorizationStatus == .approved || authorizationStatus == .approvedWithDataAccess
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = AuthorizationService.status
    }

    func refreshSystemState() {
        isRefreshingSystemState = true
        refreshAuthorizationStatus()
        reloadPersistedSelection()
        hasRefreshedSystemState = true
        isRefreshingSystemState = false
    }

    func requestAuthorization() async {
        isRequestingAuthorization = true
        lastErrorMessage = nil
        defer { isRequestingAuthorization = false }

        do {
            try await AuthorizationService.requestIndividualAuthorization()
            refreshAuthorizationStatus()
        } catch {
            refreshAuthorizationStatus()
            lastErrorMessage = error.localizedDescription
        }
    }

    func validateAndPersistSelectedApp() {
        let applicationCount = activitySelection.applicationTokens.count
        let categoryCount = activitySelection.categoryTokens.count
        let webDomainCount = activitySelection.webDomainTokens.count

        guard categoryCount == 0 else {
            hasPersistedAppSelection = false
            selectionValidationMessage = "Categories are out of scope for this spike. Select one app only."
            return
        }

        guard webDomainCount == 0 else {
            hasPersistedAppSelection = false
            selectionValidationMessage = "Web domains are out of scope for this spike. Select one app only."
            return
        }

        guard applicationCount > 0 else {
            hasPersistedAppSelection = false
            selectionValidationMessage = "Select one app before saving."
            return
        }

        guard applicationCount == 1, let applicationToken = activitySelection.applicationTokens.first else {
            hasPersistedAppSelection = false
            selectionValidationMessage = "Select exactly one app. Multiple apps are not accepted yet."
            return
        }

        var singleAppSelection = FamilyActivitySelection()
        singleAppSelection.applicationTokens = [applicationToken]

        do {
            try SelectionPersistence.saveSelectedAppSelection(singleAppSelection)
            activitySelection = singleAppSelection
            hasPersistedAppSelection = true
            selectionValidationMessage = "One app selected and saved."
        } catch {
            hasPersistedAppSelection = false
            selectionValidationMessage = "Could not save the selected app: \(error.localizedDescription)"
        }
    }

    func reloadPersistedSelection(showLoadedMessage: Bool = false) {
        do {
            guard let persistedSelection = try SelectionPersistence.loadSelectedAppSelection() else {
                hasPersistedAppSelection = false
                if showLoadedMessage {
                    selectionValidationMessage = "No saved app selection found."
                }
                return
            }

            guard isValidOneAppSelection(persistedSelection) else {
                hasPersistedAppSelection = false
                selectionValidationMessage = "Saved selection is invalid. Select exactly one app again."
                return
            }

            activitySelection = persistedSelection
            hasPersistedAppSelection = true
            if showLoadedMessage {
                selectionValidationMessage = "Saved one-app selection loaded."
            }
        } catch {
            hasPersistedAppSelection = false
            selectionValidationMessage = "Could not load saved app selection: \(error.localizedDescription)"
        }
    }

    private func isValidOneAppSelection(_ selection: FamilyActivitySelection) -> Bool {
        selection.applicationTokens.count == 1
            && selection.categoryTokens.isEmpty
            && selection.webDomainTokens.isEmpty
    }
}
