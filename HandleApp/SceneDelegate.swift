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
        print("Scene delegate started")
            guard let windowScene = (scene as? UIWindowScene) else { return }
            let window = UIWindow(windowScene: windowScene)
            self.window = window

            // 2. Wrap the async setup in a Task
            Task {
                await setupAuthListener()
            }

        Task {
            if let user = SupabaseManager.shared.client.auth.currentUser {
                do {
                    // Try to fetch something from the database
                    // If the user was deleted, this will FAIL
                    try await SupabaseManager.shared.client.from("profiles").select().execute()
                    routeUser(user)
                } catch {
                    // If it fails, the user is likely deleted or token expired
                    try? await SupabaseManager.shared.client.auth.signOut()
                }
            } else {
                showLogin(window: window)
            }
        }

            window.makeKeyAndVisible()
        }

        // Helper to handle the routing logic
        private func routeUser(_ user: User) {
            guard let window = self.window else { return }
            let userId = user.id.uuidString
            let userKey = "hasCompletedOnboarding_\(userId)"
            let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: userKey)

            if hasCompletedOnboarding {
                showMainApp(window: window)
            } else {
                showOnboardingQuiz(window: window)
            }
        }

        // 4. This is where the async magic happens
        private func setupAuthListener() async {
            // In the new Supabase SDK, onAuthStateChange is an AsyncStream
            print("Setting up auth listner")
            for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
                print("Auth Event: \(event)")
                
                await MainActor.run {
                    guard let window = self.window else { return }
                    
                    // If logged out, force the login screen
                    if event == .signedOut || session == nil {
                        self.showLogin(window: window)
                        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
                    }
                    // Optional: If they just signed in, you could also route them here
                    else if event == .signedIn, let user = session?.user {
                        self.routeUser(user)
                    }
                }
            }
        }

        // MARK: - Routing Methods (Keep these as you had them)
        func showLogin(window: UIWindow) {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginAuthVC")
            window.rootViewController = loginVC
        }

        func showOnboardingQuiz(window: UIWindow) {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingParentVC")
            window.rootViewController = onboardingVC
        }

        func showMainApp(window: UIWindow) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarVC")
            window.rootViewController = tabBarVC
        }
        
    
//    func showOnboarding(window: UIWindow) {
//        let storyboard = UIStoryboard(name: "Profile", bundle: nil) 
//        
//        let onboardingVC = storyboard.instantiateViewController(withIdentifier: "LoginAuthVC")
// 
//        window.rootViewController = onboardingVC
//    }

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

