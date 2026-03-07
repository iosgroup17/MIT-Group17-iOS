//
//  LoginAuthViewController.swift
//  HandleApp
//
//  Created by SDC_USER on 03/02/26.
//

import UIKit
import Supabase
import AuthenticationServices
import GoogleSignIn

class LoginAuthViewController: UIViewController {

    @IBOutlet weak var footerButton: UIButton! // The "Don't have an account?" button
    
    // MARK: - State
    // This variable tracks which mode we are in
    var isSignUpMode = false {
        didSet { updateUI() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize UI for Login mode
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Replace "WelcomeViewController" with the actual ID of your first screen
        let hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
            if !hasSeenWelcome {
                if let welcomeVC = storyboard?.instantiateViewController(withIdentifier: "WelcomeViewController") {
                    welcomeVC.modalPresentationStyle = .pageSheet
                    self.present(welcomeVC, animated: true) {
                        UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                    }
                }
            }
    }
    
    // MARK: - UI Configuration
    func updateUI() {
        // Toggle texts based on the mode
        if isSignUpMode {
            setAttributedFooter(question: "Already have an account?", action: "Log In")
        } else {
            setAttributedFooter(question: "Don't have an account?", action: "Sign Up")
        }
    }
    
    // Helper to make the footer look professional (Two colors)
    func setAttributedFooter(question: String, action: String) {
        let fullText = "\(question) \(action)"
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // Color the "Action" part blue/bold
        let range = (fullText as NSString).range(of: action)
        attributedString.addAttributes([
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.boldSystemFont(ofSize: 14)
        ], range: range)
        
        // Color the "Question" part gray
        let questionRange = (fullText as NSString).range(of: question)
        attributedString.addAttributes([
            .foregroundColor: UIColor.darkGray,
            .font: UIFont.systemFont(ofSize: 14)
        ], range: questionRange)
        
        footerButton.setAttributedTitle(attributedString, for: .normal)
    }

    // MARK: - Interactions
    
    // 1. Footer Tapped -> Switch Mode
    @IBAction func footerTapped(_ sender: UIButton) {
        // Animate the transition slightly for polish
        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve) {
            self.isSignUpMode.toggle()
        }
    }

    // 2. Main Action (Login OR Sign Up)
    
    
    // MARK: - 3. Google Login
    @IBAction func googleTapped(_ sender: UIButton) {
            
            // 1. Safely read the keys from Info.plist
            guard let iosClientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
                  let webClientID = Bundle.main.object(forInfoDictionaryKey: "WebGIDClientID") as? String else {
                showAlert(message: "Configuration Error: Missing Google Client IDs.")
                return
            }
            
            // 2. Configure Google Sign-In to use BOTH keys
            let config = GIDConfiguration(clientID: iosClientID, serverClientID: webClientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // 3. Present the Sign-In sheet
            GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
                if let error = error {
                    self?.showAlert(message: "Google Error: \(error.localizedDescription)")
                    return
                }
                
                guard let result = result,
                      let idToken = result.user.idToken?.tokenString else { return }
                
                Task {
                    do {
                        // 4. Send the correct token to Supabase
                        try await SupabaseManager.shared.client.auth.signInWithIdToken(
                            credentials: .init(provider: .google, idToken: idToken)
                        )
                        
                        await self?.navigateToHome()
                    } catch {
                        await self?.showAlert(message: "Supabase Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    
    
    

    // MARK: - Navigation Helper
    func navigateToHome() {
            Task {
                let remoteData = await SupabaseManager.shared.fetchUserOnboardingData()
                OnboardingDataStore.shared.syncWithRemoteData(remoteData)
                
                guard let userId = SupabaseManager.shared.client.auth.currentUser?.id.uuidString else {
                    await self.showAlert(message: "Auth Error: Could not get user ID.")
                    return
                }
                
                let userKey = "hasCompletedOnboarding_\(userId)"
                
                if !remoteData.isEmpty {
                    UserDefaults.standard.set(true, forKey: userKey)
                }

                DispatchQueue.main.async {
                    if let window = self.view.window,
                       let sceneDelegate = window.windowScene?.delegate as? SceneDelegate {
                        
                        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: userKey)
                        
                        if hasCompletedOnboarding {
                            sceneDelegate.showMainApp(window: window)
                        } else {
                            sceneDelegate.showOnboardingQuiz(window: window)
                        }
                        
                        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromRight, animations: nil)
                    }
                }
            }
        }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}



