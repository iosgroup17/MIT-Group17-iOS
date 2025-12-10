//import UIKit
//import AuthenticationServices // 1. IMPORT THIS FRAMEWORK
//
//// 2. Add this protocol so we can tell the browser where to show up
//class AuthViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
//
//    var webAuthSession: ASWebAuthenticationSession?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        navigationController?.setNavigationBarHidden(true, animated: false)
//    }
//
//    // MARK: - The Magic Browser Function
//    func startAuth(url: String, scheme: String) {
//        guard let authURL = URL(string: url) else { return }
//
//        // Initialize the session
//        self.webAuthSession = ASWebAuthenticationSession(
//            url: authURL,
//            callbackURLScheme: scheme) { callbackURL, error in
//                
//                // This block runs when the browser closes
//                if let error = error {
//                    print("Auth Canceled or Failed: \(error.localizedDescription)")
//                    return
//                }
//                
//                if let callbackURL = callbackURL {
//                    print("SUCCESS! We got the token details: \(callbackURL)")
//                    // Here is where we would save the login data
//                }
//            }
//
//        // Settings to make it look professional
//        self.webAuthSession?.presentationContextProvider = self
//        self.webAuthSession?.prefersEphemeralWebBrowserSession = false // Remembers cookies (good for login)
//        
//        // Start the browser!
//        self.webAuthSession?.start()
//    }
//
//    // MARK: - Button Actions
//    
//    @IBAction func didTapTwitter(_ sender: UIButton) {
//        print("Twitter Tapped")
//        // Example: Opening Twitter (This is a dummy link for now)
//        startAuth(url: "https://twitter.com/login", scheme: "handle-app")
//    }
//    
//    @IBAction func didTapInstagram(_ sender: UIButton) {
//        print("Instagram Tapped")
//        startAuth(url: "https://instagram.com/accounts/login", scheme: "handle-app")
//    }
//    
//    @IBAction func didTapLinkedIn(_ sender: UIButton) {
//        print("LinkedIn Tapped")
//        startAuth(url: "https://www.linkedin.com/login", scheme: "handle-app")
//    }
//    
//    @IBAction func didTapSkip(_ sender: UIButton) {
//        print("Skip/Continue Tapped")
//                
//                // CHECK: Is this screen currently presented as a popup (Modal)?
//                if self.presentingViewController != nil {
//                    // YES: We are a popup. Just close us to reveal the Analytics screen behind us.
//                    self.dismiss(animated: true, completion: nil)
//                } else {
//                    // NO: We are the main screen (Onboarding). Push to Analytics.
//                    performSegue(withIdentifier: "goToAnalytics", sender: self)
//                }
//    }
//    
//    // MARK: - ASWebAuthentication Protocol
//    // This tells the browser to use the current window
//    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
//        return self.view.window!
//    }
//}


import UIKit
import AuthenticationServices // 1. REQUIRED: Import the Auth Framework

// 2. Add the ContextProviding protocol to the class definition
class AuthViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {

    // 3. Create a variable to hold the browser session
    var webAuthSession: ASWebAuthenticationSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Hides the top navigation bar so the login screen looks clean
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - The OAuth Engine ⚙️
    // This function can handle ANY platform (LinkedIn, X, Insta)
    func startAuth(authURL: String, callbackScheme: String) {
        
        guard let url = URL(string: authURL) else { return }

        // Initialize the secure browser session
        self.webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme) { callbackURL, error in
                
                // 1. Handle Errors (User clicked Cancel)
                if let error = error {
                    print("Auth Canceled or Failed: \(error.localizedDescription)")
                    return
                }
                
                // 2. Handle Success (We got a URL back!)
                if let callbackURL = callbackURL {
                    // The URL looks like: handleapp://callback?code=12345ABCDE&state=...
                    print("🔥 SUCCESS! Redirected URL: \(callbackURL)")
                    
                    // 3. Extract the 'code' parameter
                    if let code = self.getQueryStringParameter(url: callbackURL.absoluteString, param: "code") {
                        print("✅ AUTH CODE: \(code)")
                        
                        // TODO: Save this code or swap it for a Token
                        // For now, let's behave as if we logged in:
                        self.handleSuccessfulLogin()
                    }
                }
            }

        // Settings to make it look professional
        self.webAuthSession?.presentationContextProvider = self
        self.webAuthSession?.prefersEphemeralWebBrowserSession = false // False = Remember cookies (easier login)
        
        // Launch the browser!
        self.webAuthSession?.start()
    }

    // Helper to find the "code=" part of the URL string
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    // Logic to handle what happens after login
    func handleSuccessfulLogin() {
        // UI: You could turn the button green here
        // Navigation: Go to Analytics
        // dismissal of browser is automatic
        
        // Delay slightly to let the browser dismiss animation finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performSegue(withIdentifier: "goToAnalytics", sender: self)
        }
    }

    // MARK: - Button Actions
    
    @IBAction func didTapLinkedIn(_ sender: UIButton) {
        print("LinkedIn Button Tapped")
        
        // ⚠️ REPLACE THIS WITH YOUR REAL CLIENT ID FROM LINKEDIN DEVELOPER PORTAL
        let clientID = "YOUR_CLIENT_ID_HERE"
        let redirectURI = "handleapp://callback" // Must match what you put in Info.plist
        let state = "random_string"
        let scope = "openid profile email" // The permissions we are asking for
        
        // The Official LinkedIn OAuth URL
        let authURL = "https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=\(clientID)&redirect_uri=\(redirectURI)&state=\(state)&scope=\(scope)"
        
        startAuth(authURL: authURL, callbackScheme: "handleapp")
    }
    
    @IBAction func didTapTwitter(_ sender: UIButton) {
        print("Twitter Tapped - Need Client ID")
        // You will add the Twitter URL logic here later
    }
    
    @IBAction func didTapInstagram(_ sender: UIButton) {
        print("Instagram Tapped - Need Client ID")
        // You will add the Instagram URL logic here later
    }
    
    // MARK: - Navigation
    @IBAction func didTapSkip(_ sender: UIButton) {
        print("Skip Tapped")
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "goToAnalytics", sender: self)
        }
    }
    
    // MARK: - ASWebAuthentication Protocol
    // This tells the browser which window to appear on top of
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window!
    }
}
