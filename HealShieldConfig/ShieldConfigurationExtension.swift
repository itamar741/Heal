//
//  ShieldConfigurationExtension.swift
//  HealShieldConfig
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        supportiveConfiguration
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        supportiveConfiguration
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        supportiveConfiguration
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        supportiveConfiguration
    }

    private var supportiveConfiguration: ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: nil,
            title: ShieldConfiguration.Label(
                text: "Pause for a moment",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "You chose to protect yourself from this app. Take a breath and open Safe Place when you are ready.",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Safe Place",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor.systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor.systemBlue
            )
        )
    }
}
