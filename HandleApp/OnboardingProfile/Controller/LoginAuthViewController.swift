//
//  LoginAuthViewController.swift
//  HandleApp
//
//  Created by SDC_USER on 03/02/26.
//

import UIKit
import AuthenticationServices
import GoogleSignIn

class LoginAuthViewController: UIViewController {
    @IBOutlet weak var manualStack: UIStackView!
    @IBOutlet weak var socialStack: UIStackView!
    @IBOutlet weak var signUpButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFooterLink()
        self.manualStack.isHidden = true
        // Do any additional setup after loading the view.
    }
    @IBAction func handleAppleSignIn(_ sender: UIButton) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

        // MARK: - Google Sign In
    @IBAction func handleGoogleSignIn(_ sender: UIButton) {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            if let error = error {
                print("Google Sign-In Error: \(error.localizedDescription)")
                return
            }
            guard let result = signInResult else { return }
            
            let user = result.user
            print("Google User: \(user.profile?.name ?? "No Name")")
        }
    }
    
    @IBAction func signUpTapped(_ sender: UIButton) {
        // Animate the transition for a professional feel
        UIView.animate(withDuration: 0.3) {
            // Hide social, show manual
            self.socialStack.isHidden = true
            self.manualStack.isHidden = false
            
            // Hide the footer link since they are now in the sign-up state
            self.signUpButton.alpha = 0
            
            // Force the layout to update immediately for the animation
            self.view.layoutIfNeeded()
        }
    }
    func setupFooterLink() {
        // 1. The full string
        let fullText = "Don't have an account? Sign Up"
        
        // 2. Create the attributed string
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // 3. Find the range of "Sign Up" to make it bold/different color
        let range = (fullText as NSString).range(of: "Sign Up")
        
        attributedString.addAttributes([
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.systemTeal // Or black to match your theme
        ], range: range)
        
        // 4. Set the rest of the text to a lighter color/font
        let grayRange = (fullText as NSString).range(of: "Don't have an account?")
        attributedString.addAttributes([
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ], range: grayRange)
        
        // 5. Assign to button
        signUpButton.setAttributedTitle(attributedString, for: .normal)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension LoginAuthViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            print("Apple User ID: \(userIdentifier)")
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In Failed: \(error.localizedDescription)")
    }
}

