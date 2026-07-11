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

    func refreshAuthorizationStatus() {
        authorizationStatus = AuthorizationService.status
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
}
