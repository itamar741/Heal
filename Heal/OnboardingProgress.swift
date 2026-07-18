//
//  OnboardingProgress.swift
//  Heal
//
//  App-level onboarding product state. Owns only onboarding-specific
//  persisted flags — not Screen Time, Safari extension, functional-test,
//  or System Website Filtering technical state.
//

import Foundation
import Observation

@Observable
@MainActor
final class OnboardingProgress {
    private static let hasCompletedOnboardingKey = "onboarding.hasCompletedOnboarding"
    private static let hasAcknowledgedIntroductionKey = "onboarding.hasAcknowledgedIntroduction"

    private let userDefaults: UserDefaults

    /// Single observable reflection of the persisted introduction acknowledgement.
    /// Mutate only through `acknowledgeIntroduction()` or temporary test reset.
    private(set) var hasAcknowledgedIntroduction: Bool

    /// Single observable reflection of the persisted completion flag.
    /// Mutate only through `markOnboardingCompleted()` or temporary test reset.
    private(set) var hasCompletedOnboarding: Bool

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.hasAcknowledgedIntroduction = userDefaults.bool(forKey: Self.hasAcknowledgedIntroductionKey)
        self.hasCompletedOnboarding = userDefaults.bool(forKey: Self.hasCompletedOnboardingKey)
    }

    func acknowledgeIntroduction() {
        hasAcknowledgedIntroduction = true
        userDefaults.set(true, forKey: Self.hasAcknowledgedIntroductionKey)
    }

    func markOnboardingCompleted() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: Self.hasCompletedOnboardingKey)
    }

    /// Temporary testing helper. Clears every OnboardingProgress-owned persisted
    /// flag so M2 derived steps can be re-exercised without reinstalling.
    /// Does not touch Screen Time authorization or any technical service state.
    func resetTemporaryTestingState() {
        hasAcknowledgedIntroduction = false
        hasCompletedOnboarding = false
        userDefaults.removeObject(forKey: Self.hasAcknowledgedIntroductionKey)
        userDefaults.removeObject(forKey: Self.hasCompletedOnboardingKey)
    }
}
