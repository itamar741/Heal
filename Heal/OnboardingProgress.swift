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

@Observable
@MainActor
final class OnboardingProgress {
    private static let hasCompletedOnboardingKey = "onboarding.hasCompletedOnboarding"
    private static let hasAcknowledgedIntroductionKey = "onboarding.hasAcknowledgedIntroduction"
    private static let hasConfirmedSafariAllWebsitesAccessKey =
        "onboarding.hasConfirmedSafariAllWebsitesAccess"
    private static let hasConfirmedSafariPrivateBrowsingKey =
        "onboarding.hasConfirmedSafariPrivateBrowsing"

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

    func markOnboardingCompleted() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: Self.hasCompletedOnboardingKey)
    }

    /// Temporary testing helper. Clears every OnboardingProgress-owned persisted
    /// flag so M3 derived steps can be re-exercised without reinstalling.
    /// Does not touch Screen Time authorization, Safari extension enablement,
    /// Safari system settings, functional-test state, or System Website Filtering.
    func resetTemporaryTestingState() {
        hasAcknowledgedIntroduction = false
        hasConfirmedSafariAllWebsitesAccess = false
        hasConfirmedSafariPrivateBrowsing = false
        hasCompletedOnboarding = false
        userDefaults.removeObject(forKey: Self.hasAcknowledgedIntroductionKey)
        userDefaults.removeObject(forKey: Self.hasConfirmedSafariAllWebsitesAccessKey)
        userDefaults.removeObject(forKey: Self.hasConfirmedSafariPrivateBrowsingKey)
        userDefaults.removeObject(forKey: Self.hasCompletedOnboardingKey)
    }
}
