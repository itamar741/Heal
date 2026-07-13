//
//  AuthorizationService.swift
//  Heal
//

import FamilyControls
import Foundation

enum AuthorizationService {
    static var status: AuthorizationStatus {
        AuthorizationCenter.shared.authorizationStatus
    }

    static func requestIndividualAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
}
