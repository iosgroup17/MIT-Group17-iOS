import UIKit
import AuthenticationServices // Import the Auth Framework

// Add the ContextProviding protocol to the class definition 
// this protocol allows us to specify where the authentication session should be presented as in which window or view it should be attached to. This is important for managing the user experience during the authentication process.
class AuthViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {


    // Create a variable to hold the browser session
    var webAuthSession: ASWebAuthenticationSession?
    var onCompletion: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Hides the top navigation bar as it is not needed on this screen
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBAction func skipButtonTapped(_ sender: Any) {
        onCompletion?(false)
        dismiss(animated: true)
    }
    
    // When success in linkedIn instagram button function
    // onCompletion?(true)
    // dismiss(animated: true)

    // This function can handle ANY platform (LinkedIn, X, Insta)
    func startAuth(authURL: String, callbackScheme: String) {
        
        guard let url = URL(string: authURL) else { return }

        // Initialize the secure browser session
        self.webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme) { callbackURL, error in
                
                // Handle Errors (User clicked Cancel)
                if let error = error {
                    print("Auth Canceled or Failed: \(error.localizedDescription)")
                    return
                }
                
                // Handle Success (We got a URL back!)
                if let callbackURL = callbackURL {
                    // The URL looks like: handleapp://callback?code=12345ABCDE&state=...
                    print("Successful Verification! Redirected URL: \(callbackURL)")
                    
                    // Extract the 'code' parameter
                    if let code = self.getQueryStringParameter(url: callbackURL.absoluteString, param: "code") {
                        print("AUTH CODE: \(code)")
                        
                        // TODO: Save this code or swap it for a Token
                        // For now, let's behave as if we logged in:
                        self.handleSuccessfulLogin()
                    }
                }
            }

        // Settings to make it look professional
        self.webAuthSession?.presentationContextProvider = self
        // this setting presentationContextProvider is used to specify the context in which the authentication session should be presented. by setting it to self, we are indicating that the current view controller will provide the necessary context for displaying the authentication session. this is important for managing the user experience during the authentication process, ensuring that the session appears in the appropriate window or view.
        self.webAuthSession?.prefersEphemeralWebBrowserSession = false 
        // this is false to remember cookies, so users don't have to log in every time
        
        // Launch the browser!
        self.webAuthSession?.start()
    }

    // Helper to find the "code=" part of the URL string it allows the app to securely obtain an access token from the authentication server, which is then used to access protected resources on behalf of the user.
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    // Logic to handle what happens after login
    func handleSuccessfulLogin() {
        // Navigation: Go to Analytics
        // dismissal of browser is automatic
        
        // Delay slightly to let the browser dismiss animation finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performSegue(withIdentifier: "goToAnalytics", sender: self)
        }
    }

    
    @IBAction func didTapLinkedIn(_ sender: UIButton) {
        print("LinkedIn Button Tapped")
        
        // Will replace this with real CLIENT ID Linkedin Dev Portal
        let clientID = "YOUR_CLIENT_ID_HERE"
        let redirectURI = "handleapp://callback" // Must match what was put in Info.plist
        // Info.plist is a file that contains config settings for the app
        let state = "random_string"
        let scope = "openid profile email" // The permissions we are asking for
        
        // The Official LinkedIn OAuth URL
        let authURL = "https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=\(clientID)&redirect_uri=\(redirectURI)&state=\(state)&scope=\(scope)"
        
        startAuth(authURL: authURL, callbackScheme: "handleapp")
    }
    
    @IBAction func didTapTwitter(_ sender: UIButton) {
        print("Twitter Tapped - Need Client ID")
        //Twitter URL logic here later
    }
    
    @IBAction func didTapInstagram(_ sender: UIButton) {
        print("Instagram Tapped - Need Client ID")
        //Instagram URL logic here later
    }
    
    
    @IBAction func didTapSkip(_ sender: UIButton) {
        // this if block checks if current vc was presented as modal or not if yes then it dismisses else it performs segue
        print("Skip Tapped")
        if self.presentingViewController != nil {
            
            self.dismiss(animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "goToAnalytics", sender: self)
        }
    }
    
    // MARK: - ASWebAuthentication Protocol
    // This tells the browser to use the current window for presentation of the authentication session
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window!
    }
}
