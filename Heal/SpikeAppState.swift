//
//  SpikeAppState.swift
//  Heal
//

import FamilyControls
import Foundation
import Observation

struct LaunchContext {
    var openedFromShieldHandoff = false
    var sessionId: String?
    var createdAt: Date?
}

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
    var shieldStatusMessage: String?
    var isShieldApplied = false
    var handoffStatusMessage = "No handoff marker detected."
    var detectedHandoffSessionID: String?
    var detectedHandoffCreatedAt: Date?
    var pendingSafePlaceEntry = false
    var launchContext = LaunchContext()
    var handoffConsumptionMessage: String?

    init() {
        reloadPersistedSelection()
    }

    var isAuthorizationApproved: Bool {
        authorizationStatus == .approved || authorizationStatus == .approvedWithDataAccess
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = AuthorizationService.status
        syncShieldAppliedStateFromSystem()
    }

    func refreshSystemState() {
        isRefreshingSystemState = true
        authorizationStatus = AuthorizationService.status
        reloadPersistedSelection()
        refreshHandoffDebugStatus()
        syncShieldAppliedStateFromSystem()
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
            authorizationStatus = AuthorizationService.status
            syncShieldAppliedStateFromSystem()
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

    func applyShieldToPersistedSelection() {
        do {
            try ShieldService.shared.applyShieldToPersistedSelection()
            syncShieldAppliedStateFromSystem()
            if isShieldApplied {
                shieldStatusMessage = "Shield applied to the saved app."
            } else {
                shieldStatusMessage = "Could not verify shield was applied."
            }
        } catch {
            syncShieldAppliedStateFromSystem()
            shieldStatusMessage = "Could not apply shield: \(error.localizedDescription)"
        }
    }

    func clearShield() {
        ShieldService.shared.clearShield()
        syncShieldAppliedStateFromSystem()
        if !isShieldApplied {
            shieldStatusMessage = "Shield cleared."
        } else {
            shieldStatusMessage = "Could not verify shield was cleared."
        }
    }

    private func syncShieldAppliedStateFromSystem() {
        guard isAuthorizationApproved else {
            isShieldApplied = false
            shieldStatusMessage = "Screen Time access is not approved. Shield status is unavailable."
            return
        }

        do {
            isShieldApplied = try ShieldService.shared.isPersistedSelectionShielded()
            shieldStatusMessage = nil
        } catch {
            isShieldApplied = false
            shieldStatusMessage = "Could not read shield status: \(error.localizedDescription)"
        }
    }

    func refreshHandoffDebugStatus() {
        do {
            guard let marker = try HandoffStore.readMarker() else {
                detectedHandoffSessionID = nil
                detectedHandoffCreatedAt = nil
                handoffStatusMessage = "No pending handoff marker detected."
                return
            }

            detectedHandoffSessionID = marker.sessionId
            detectedHandoffCreatedAt = Date(timeIntervalSince1970: marker.createdAt)
            handoffStatusMessage = "Pending handoff marker detected."
        } catch {
            detectedHandoffSessionID = nil
            detectedHandoffCreatedAt = nil
            handoffStatusMessage = "Could not read handoff marker: \(error.localizedDescription)"
        }
    }

    func evaluatePendingSafePlaceEntry() {
        guard !pendingSafePlaceEntry else {
            return
        }

        do {
            guard let marker = try HandoffStore.readMarker(),
                  marker.pendingSafePlaceLaunch,
                  isSupportedHandoffTriggerKind(marker.triggerKind),
                  !marker.sessionId.isEmpty else {
                return
            }

            launchContext = LaunchContext(
                openedFromShieldHandoff: true,
                sessionId: marker.sessionId,
                createdAt: Date(timeIntervalSince1970: marker.createdAt)
            )
            pendingSafePlaceEntry = true
        } catch {
            handoffConsumptionMessage = "Could not read handoff marker for routing: \(error.localizedDescription)"
        }
    }

    func consumeHandoffMarkerAfterPresentation() {
        do {
            try HandoffStore.consumeMarker()
            handoffConsumptionMessage = "Handoff marker consumed."
            refreshHandoffDebugStatus()
        } catch {
            handoffConsumptionMessage = "Could not consume handoff marker: \(error.localizedDescription)"
        }
    }

    func dismissSafePlaceEntry() {
        pendingSafePlaceEntry = false
        launchContext = LaunchContext()
        handoffConsumptionMessage = nil
    }

    private func isSupportedHandoffTriggerKind(_ triggerKind: String) -> Bool {
        triggerKind == "app" || triggerKind == "webDomain"
    }
}
