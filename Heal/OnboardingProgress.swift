//
//  OnboardingProgress.swift
//  Heal
//
//  App-level onboarding product state. Owns only onboarding-specific
//  persisted flags — not Screen Time, Safari extension enablement,
//  functional-test, or System Website Filtering technical state.
//

import Foundation
import Observation

/// Persisted onboarding decision for optional System Website Filtering.
/// Actual ManagedSettings on/off remains owned by `SystemWebFilteringService`.
enum SystemWebFilteringOnboardingDecision: String, Equatable {
    case enabled
    case skipped
}

@Observable
@MainActor
final class OnboardingProgress {
    private static let hasCompletedOnboardingKey = "onboarding.hasCompletedOnboarding"
    private static let hasAcknowledgedIntroductionKey = "onboarding.hasAcknowledgedIntroduction"
    private static let hasConfirmedSafariAllWebsitesAccessKey =
        "onboarding.hasConfirmedSafariAllWebsitesAccess"
    private static let hasConfirmedSafariPrivateBrowsingKey =
        "onboarding.hasConfirmedSafariPrivateBrowsing"
    private static let systemWebFilteringDecisionKey =
        "onboarding.systemWebFilteringDecision"

    private let userDefaults: UserDefaults

    /// Single observable reflection of the persisted introduction acknowledgement.
    /// Mutate only through `acknowledgeIntroduction()` or temporary test reset.
    private(set) var hasAcknowledgedIntroduction: Bool

    /// Single observable reflection of the persisted All Websites manual confirmation.
    /// Mutate only through `confirmSafariAllWebsitesAccess()` or temporary test reset.
    /// Not a technical verification — Apple provides no API for this setting.
    private(set) var hasConfirmedSafariAllWebsitesAccess: Bool

    /// Single observable reflection of the persisted Private Browsing manual confirmation.
    /// Mutate only through `confirmSafariPrivateBrowsing()` or temporary test reset.
    /// Not a technical verification — Apple provides no API for this setting.
    private(set) var hasConfirmedSafariPrivateBrowsing: Bool

    /// Single optional enum for the M5 Enable/Skip decision.
    /// `nil` means no decision yet. Mutate only through record methods or temporary test reset.
    /// Does not mirror live ManagedSettings filter state.
    private(set) var systemWebFilteringDecision: SystemWebFilteringOnboardingDecision?

    /// Single observable reflection of the persisted completion flag.
    /// Mutate only through `markOnboardingCompleted()` or temporary test reset.
    private(set) var hasCompletedOnboarding: Bool

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.hasAcknowledgedIntroduction = userDefaults.bool(forKey: Self.hasAcknowledgedIntroductionKey)
        self.hasConfirmedSafariAllWebsitesAccess = userDefaults.bool(
            forKey: Self.hasConfirmedSafariAllWebsitesAccessKey
        )
        self.hasConfirmedSafariPrivateBrowsing = userDefaults.bool(
            forKey: Self.hasConfirmedSafariPrivateBrowsingKey
        )
        if let rawValue = userDefaults.string(forKey: Self.systemWebFilteringDecisionKey) {
            self.systemWebFilteringDecision = SystemWebFilteringOnboardingDecision(rawValue: rawValue)
        } else {
            self.systemWebFilteringDecision = nil
        }
        self.hasCompletedOnboarding = userDefaults.bool(forKey: Self.hasCompletedOnboardingKey)
    }

    func acknowledgeIntroduction() {
        hasAcknowledgedIntroduction = true
        userDefaults.set(true, forKey: Self.hasAcknowledgedIntroductionKey)
    }

    func confirmSafariAllWebsitesAccess() {
        hasConfirmedSafariAllWebsitesAccess = true
        userDefaults.set(true, forKey: Self.hasConfirmedSafariAllWebsitesAccessKey)
    }

    func confirmSafariPrivateBrowsing() {
        hasConfirmedSafariPrivateBrowsing = true
        userDefaults.set(true, forKey: Self.hasConfirmedSafariPrivateBrowsingKey)
    }

    /// Records a successful Enable choice. Call only after
    /// `SystemWebFilteringService.enableSystemWebsiteFiltering()` succeeds.
    func recordSystemWebFilteringEnabledDecision() {
        systemWebFilteringDecision = .enabled
        userDefaults.set(
            SystemWebFilteringOnboardingDecision.enabled.rawValue,
            forKey: Self.systemWebFilteringDecisionKey
        )
    }

    /// Records an explicit Skip choice. Does not change ManagedSettings filter state.
    func recordSystemWebFilteringSkippedDecision() {
        systemWebFilteringDecision = .skipped
        userDefaults.set(
            SystemWebFilteringOnboardingDecision.skipped.rawValue,
            forKey: Self.systemWebFilteringDecisionKey
        )
    }

    func markOnboardingCompleted() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: Self.hasCompletedOnboardingKey)
    }

    /// Temporary testing helper. Clears every OnboardingProgress-owned persisted
    /// flag so derived steps can be re-exercised without reinstalling.
    /// Does not touch Screen Time authorization, Safari extension enablement,
    /// Safari system settings, functional-test state, or System Website Filtering.
    func resetTemporaryTestingState() {
        hasAcknowledgedIntroduction = false
        hasConfirmedSafariAllWebsitesAccess = false
        hasConfirmedSafariPrivateBrowsing = false
        systemWebFilteringDecision = nil
        hasCompletedOnboarding = false
        userDefaults.removeObject(forKey: Self.hasAcknowledgedIntroductionKey)
        userDefaults.removeObject(forKey: Self.hasConfirmedSafariAllWebsitesAccessKey)
        userDefaults.removeObject(forKey: Self.hasConfirmedSafariPrivateBrowsingKey)
        userDefaults.removeObject(forKey: Self.systemWebFilteringDecisionKey)
        userDefaults.removeObject(forKey: Self.hasCompletedOnboardingKey)
    }
}
