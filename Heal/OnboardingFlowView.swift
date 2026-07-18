//
//  OnboardingFlowView.swift
//  Heal
//
//  Minimal onboarding shell for M1 navigation validation only.
//  Does not implement Safari, Screen Time, manual permission,
//  functional-test, or System Website Filtering product steps.
//

import SwiftUI

struct OnboardingFlowView: View {
    @Bindable var onboarding: OnboardingProgress

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Onboarding Foundation")
                    .font(.largeTitle.bold())

                Text(
                    "M1 shell only. This screen validates onboarding ownership and "
                        + "root navigation. Product setup steps are not implemented yet."
                )
                .font(.body)
                .foregroundStyle(.secondary)

                Text("Completion status: incomplete")
                    .font(.headline)

                Button {
                    onboarding.markOnboardingCompleted()
                } label: {
                    Text("Mark Onboarding Complete (M1 Test)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Text(
                    "Temporary test control. Use only to validate routing and "
                        + "persistence. Not final product behavior. "
                        + "To return to incomplete onboarding, delete and reinstall the app."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    OnboardingFlowView(onboarding: OnboardingProgress())
}
