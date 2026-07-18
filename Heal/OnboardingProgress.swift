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

    private let userDefaults: UserDefaults

    /// Single observable reflection of the persisted completion flag.
    /// Mutate only through `markOnboardingCompleted()`.
    private(set) var hasCompletedOnboarding: Bool

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.hasCompletedOnboarding = userDefaults.bool(forKey: Self.hasCompletedOnboardingKey)
    }

    func markOnboardingCompleted() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: Self.hasCompletedOnboardingKey)
    }
}
