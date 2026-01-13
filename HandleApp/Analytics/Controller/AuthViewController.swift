import UIKit
import AuthenticationServices

class AuthViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {

    var webAuthSession: ASWebAuthenticationSession?
    var onCompletion: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Twitter Action
    @IBAction func didTapTwitter(_ sender: UIButton) {
        print("🔵 Starting Twitter Auth...")
        
        guard let authURL = SocialAuthManager.shared.getTwitterAuthURL(),
              let url = URL(string: authURL) else { return }
        
        self.webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "handleapp") { [weak self] callbackURL, error in
                
                guard let self = self else { return }
                if let error = error { print("❌ Auth Failed: \(error.localizedDescription)"); return }
                
                if let callbackURL = callbackURL,
                   let code = self.getQueryStringParameter(url: callbackURL.absoluteString, param: "code") {
                    
                    print("✅ Got Twitter Code: \(code)")
                    
                    SocialAuthManager.shared.exchangeTwitterCodeForToken(code: code) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let token):
                                print("🎉 TWITTER TOKEN SECURED: \(token)")
                                
                                Task {
                                    await SupabaseManager.shared.saveSocialToken(platform: "twitter", token: token)
                                    self.handleSuccessfulLogin()
                                }
                                
                            case .failure(let error):
                                print("❌ Token Exchange Failed: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        
        self.webAuthSession?.presentationContextProvider = self
        // Set to TRUE if you want to force the login screen to appear every time (good for testing)
        // Set to FALSE if you want it to remember you (good for real users)
        self.webAuthSession?.prefersEphemeralWebBrowserSession = true
        self.webAuthSession?.start()
    }

    // MARK: - Instagram Action
    @IBAction func didTapInstagram(_ sender: UIButton) {
        print("🟣 Starting Instagram Auth...")
        let authURL = SocialAuthManager.shared.getInstagramAuthURL()
        guard let url = URL(string: authURL) else { return }

        // Note: For Instagram, we look for 'https' callback because we used a dummy web URL
        self.webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "https") { [weak self] callbackURL, error in
                
                guard let self = self else { return }
                if let error = error { print("❌ Auth Failed: \(error.localizedDescription)"); return }
                
                // Intercept the redirect to handleapp.com
                if let callbackURL = callbackURL,
                   callbackURL.absoluteString.starts(with: "https://handleapp.com/auth/") {
                    
                    // Note: If using Implicit Flow (Token in URL), parse token directly.
                    // If using Code Flow, parse code.
                    // Assuming token flow for Business Login simplicity:
                    if let token = self.getQueryStringParameter(url: callbackURL.absoluteString.replacingOccurrences(of: "#", with: "?"), param: "access_token") {
                         
                         print("🎉 INSTAGRAM TOKEN SECURED: \(token)")
                         Task {
                             await SupabaseManager.shared.saveSocialToken(platform: "instagram", token: token)
                             self.handleSuccessfulLogin()
                         }
                    }
                }
            }
        self.webAuthSession?.presentationContextProvider = self
        self.webAuthSession?.prefersEphemeralWebBrowserSession = true
        self.webAuthSession?.start()
    }

    
    @IBAction func didTapLinkedIn(_ sender: UIButton) {
        print("🔵 Starting LinkedIn Auth...")
        
        let authURL = SocialAuthManager.shared.getLinkedInAuthURL()
        guard let url = URL(string: authURL) else { return }
        
        // 1. Set the callback scheme to "https" because that's what LinkedIn is sending
        self.webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "https") { [weak self] callbackURL, error in
                
                guard let self = self else { return }
                if let error = error { return }
                
                // 2. Intercept the redirect by checking the string
                if let callbackURL = callbackURL,
                   callbackURL.absoluteString.starts(with: "https://handleapp.com/auth/") {
                    
                    print("✅ Intercepted LinkedIn HTTPS Callback!")
                    
                    // 3. Extract the code from the intercepted URL
                    if let code = self.getQueryStringParameter(url: callbackURL.absoluteString, param: "code") {
                        
                        SocialAuthManager.shared.exchangeLinkedInCodeForToken(code: code) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let token):
                                    Task {
                                        // 4. Save to Supabase
                                        await SupabaseManager.shared.saveSocialToken(platform: "linkedin", token: token)
                                        // 5. GO TO ANALYTICS
                                        self.handleSuccessfulLogin()
                                    }
                                case .failure(let error):
                                    print("❌ LinkedIn Token Exchange Failed: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
        
        self.webAuthSession?.presentationContextProvider = self
        self.webAuthSession?.prefersEphemeralWebBrowserSession = true
        self.webAuthSession?.start()
    }
    
    // MARK: - Helper Logic
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let urlComponents = URLComponents(string: url) else { return nil }
        return urlComponents.queryItems?.first(where: { $0.name == param })?.value
    }
    
    func handleSuccessfulLogin() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performSegue(withIdentifier: "goToAnalytics", sender: self)
        }
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    @IBAction func didTapSkip(_ sender: UIButton) {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "goToAnalytics", sender: self)
        }
    }
}
