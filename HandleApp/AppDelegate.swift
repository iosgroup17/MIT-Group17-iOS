//
//  AppDelegate.swift
//  HandleApp
//
//  Created by SDC_USER on 28/11/25.
//

import UIKit
import GoogleSignIn

// MARK: - HandleHQ adaptive appearance

extension UIColor {
    /// Keep HandleHQ's teal accent while allowing neutral UI chrome to adapt to
    /// the active iOS appearance.
    static let handleCardBorder = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.16)
            : UIColor.black.withAlphaComponent(0.10)
    }

    static let handleCardShadow = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.42)
            : UIColor.black.withAlphaComponent(0.12)
    }
}

extension UIView {
    /// Applies the shared card treatment used throughout the app. The surface,
    /// stroke, and shadow are all semantic colours so they remain legible in
    /// both Light and Dark Mode.
    func applyHandleCardAppearance(cornerRadius: CGFloat = 16, shadowHost: UIView? = nil) {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 1
        layer.borderColor = UIColor.handleCardBorder.resolvedColor(with: traitCollection).cgColor
        layer.masksToBounds = false

        let host = shadowHost ?? self
        host.layer.shadowColor = UIColor.handleCardShadow.resolvedColor(with: host.traitCollection).cgColor
        host.layer.shadowOpacity = 1
        host.layer.shadowOffset = CGSize(width: 0, height: 4)
        host.layer.shadowRadius = 8
        host.layer.masksToBounds = false
    }

    /// Re-evaluates dynamic border and shadow colors for the active trait collection.
    /// Call this inside layoutSubviews() or traitCollectionDidChange to guarantee
    /// proper contrast when the user switches between Light and Dark mode.
    func refreshHandleCardAppearance(shadowHost: UIView? = nil) {
        layer.borderColor = UIColor.handleCardBorder.resolvedColor(with: traitCollection).cgColor
        let host = shadowHost ?? self
        host.layer.shadowColor = UIColor.handleCardShadow.resolvedColor(with: host.traitCollection).cgColor
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        NotificationManager.shared.requestAuthorization()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

}
