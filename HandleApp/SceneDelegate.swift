//
//  SceneDelegate.swift
//  HandleApp
//
//  Created by SDC_USER on 28/11/25.
//

import UIKit
import Supabase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            guard let windowScene = (scene as? UIWindowScene) else { return }
            let window = UIWindow(windowScene: windowScene)
            self.window = window

            // 1. Check if Supabase has a logged-in user
            if let currentUser = SupabaseManager.shared.client.auth.currentUser {
                
                // 2. Check the local flag for THIS specific user ID
                let userId = currentUser.id.uuidString
                let userKey = "hasCompletedOnboarding_\(userId)"
                let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: userKey)

                if hasCompletedOnboarding {
                    // Logged in AND this specific ID finished onboarding
                    showMainApp(window: window)
                } else {
                    // Logged in but new account (or hasn't finished onboarding)
                    showOnboardingQuiz(window: window)
                }
            } else {
                // No user logged in at all
                showLogin(window: window)
            }

            window.makeKeyAndVisible()
        }
        
        // MARK: - Routing Methods

        func showLogin(window: UIWindow) {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginAuthVC")
            window.rootViewController = loginVC
        }

        func showOnboardingQuiz(window: UIWindow) {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            // Make sure this matches the Storyboard ID of your Onboarding Parent/Controller
            let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingParentVC")
            window.rootViewController = onboardingVC
        }

        

        // Call this from wherever your logout button is
        func handleLogout() {
            guard let window = self.window else { return }
            showLogin(window: window)
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    
    func showOnboarding(window: UIWindow) {
        let storyboard = UIStoryboard(name: "Profile", bundle: nil) // Check your file name!
        
        // Instantiate the Quiz Parent VC
        let onboardingVC = storyboard.instantiateViewController(withIdentifier: "LoginAuthVC")
 
        window.rootViewController = onboardingVC
    }

    func showMainApp(window: UIWindow) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarVC")
     
        window.rootViewController = tabBarVC
    }
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

