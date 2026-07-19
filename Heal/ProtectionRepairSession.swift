//
//  ProtectionRepairSession.swift
//  Heal
//
//  App-process-scoped ephemeral state for post-onboarding protection repair.
//  Owns only the session-only “Continue to App for Now” bypass.
//  Does not persist. Does not own live technical protection state or
//  OnboardingProgress flags.
//

import Foundation
import Observation

/// Discrete post-completion repair issues derived from live technical state
/// plus the historical M5 SWF decision. Not persisted.
enum ProtectionRepairIssue: Equatable, Identifiable {
    case screenTimeAuthorization
    case safariExtension
    case systemWebFiltering

    var id: Self { self }
}

enum ProtectionRepairEvaluator {
    /// Derives current repair issues independently per protection.
    /// Safari `.checking` is not treated as a known-disabled failure.
    static func issues(
        isAuthorizationApproved: Bool,
        safariExtensionState: SafariExtensionService.ExtensionState,
        systemWebFilteringDecision: SystemWebFilteringOnboardingDecision?,
        systemFilterState: SystemWebFilteringService.FilterState
    ) -> [ProtectionRepairIssue] {
        var issues: [ProtectionRepairIssue] = []

        if !isAuthorizationApproved {
            issues.append(.screenTimeAuthorization)
        }

        switch safariExtensionState {
        case .enabled, .checking:
            break
        case .disabled, .notFound, .error:
            issues.append(.safariExtension)
        }

        // Historical `.skipped` (or nil) never produces an SWF repair issue,
        // even when live filter state is cleared or in error.
        if systemWebFilteringDecision == .enabled {
            switch systemFilterState {
            case .enabled:
                break
            case .cleared, .error:
                issues.append(.systemWebFiltering)
            }
        }

        return issues
    }
}

/// Survives ordinary root switching (including Safe Place) for the current
/// app process. Resets naturally on the next cold launch because it is not
/// persisted and is created once at `HealApp` scope.
@Observable
@MainActor
final class ProtectionRepairSession {
    /// When true, the combined repair screen is suppressed until process death.
    /// Does not alter `hasCompletedOnboarding`, the M5 decision, or live state.
    private(set) var hasDeferredRepairThisSession = false

    func deferRepairForCurrentSession() {
        hasDeferredRepairThisSession = true
    }
}
