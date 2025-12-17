//
//  SceneDelegate.swift
//  HandleApp
//
//  Created by SDC_USER on 28/11/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 1. Create the Window manually
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // 2. Decide which screen to show
        // Change this boolean to 'false' later when you are done testing!
        let alwaysShowOnboarding = false
        
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if alwaysShowOnboarding || !hasCompletedOnboarding {
            // A. Show Onboarding (No Tab Bar)
            showOnboarding(window: window)
        } else {
            // B. Show Main App (Tabs)
            showMainApp(window: window)
        }
        
        // 3. Make the window visible
        window.makeKeyAndVisible()
    }
    
    func showOnboarding(window: UIWindow) {
        // 1. Get the Onboarding Storyboard
        let storyboard = UIStoryboard(name: "Profile", bundle: nil) // Check your file name!
        
        // 2. Instantiate the Quiz Parent VC
        // Ensure your OnboardingViewController has ID "OnboardingParentVC"
        let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingParentVC")
        
        // 3. Set as Root
        window.rootViewController = onboardingVC
    }

    func showMainApp(window: UIWindow) {
        // 1. Get the Main Storyboard (Where the Tab Bar is)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // 2. Instantiate the Tab Bar Controller
        let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarVC")
        
        // 3. Set as Root
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

