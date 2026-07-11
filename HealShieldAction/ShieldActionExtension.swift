//
//  ShieldActionExtension.swift
//  HealShieldAction
//

import FamilyControls
import ManagedSettings

class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // TODO: Later write App Group handoff marker here.
            completionHandler(.openParentalControlsApp)

        case .secondaryButtonPressed:
            completionHandler(.close)

        case .firstSecondarySubmenuItemPressed:
            completionHandler(.close)

        case .secondSecondarySubmenuItemPressed:
            completionHandler(.close)

        case .thirdSecondarySubmenuItemPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }
}
