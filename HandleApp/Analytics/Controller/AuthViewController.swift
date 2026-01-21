import UIKit
import AuthenticationServices

class AuthViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {

    // adopting ASWebAuthenticationPresentationContextProviding protocol to provide presentation anchor for ASWebAuthenticationSession
    
    @IBOutlet weak var twitterButton: UIButton!
    
    @IBOutlet weak var linkedInButton: UIButton!
    @IBOutlet weak var instagramButton: UIButton!
    @IBOutlet weak var skipForNowButton: UIButton!
    
    
    var webAuthSession: ASWebAuthenticationSession? // to hold the authentication session
    var onCompletion: ((Bool) -> Void)? //this is a closure to notify when auth is complete it is used here to inform AnalyticsVC about successful connection as in handleSuccessfulLogin function

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    // disable buttons if they're already connected 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Task {
            let list = await SupabaseManager.shared.fetchConnectedPlatforms()
            if list.contains("twitter") { markButtonAsConnected(twitterButton) }
            if list.contains("linkedin") { markButtonAsConnected(linkedInButton) }
            if list.contains("instagram") { markButtonAsConnected(instagramButton) }
        }
    }

    // disable buttons if they're already connected 
    func markButtonAsConnected(_ button: UIButton) {
        DispatchQueue.main.async {
            button.isUserInteractionEnabled = false // Make it unclickable
            button.backgroundColor = .systemGray3   // Change background to grey
            button.setTitleColor(.white, for: .normal)
            button.setTitle("Connected ✓", for: .normal)
            button.alpha = 1.0
        }
    }
    
    // MARK: - Twitter Action
    @IBAction func didTapTwitter(_ sender: UIButton) {
        print("Starting Twitter Auth...")
        
        // create a URL that includes your "Client ID" and a "Code Challenge" 
        // guard let here unwraps safely, if nil then it returns immediately
        guard let authURL = SocialAuthManager.shared.getTwitterAuthURL(),
              let url = URL(string: authURL) else { return } 
              // this converts the string URL to URL object


        
        self.webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "handleapp") { [weak self] callbackURL, error in
                
                guard let self = self else { return }
                if let error = error { print("Auth Failed: \(error.localizedDescription)"); return }
                
                // extracting code from the redirect URL is done by getQueryStringParameter function
                if let callbackURL = callbackURL,
                   let code = self.getQueryStringParameter(url: callbackURL.absoluteString, param: "code") {
                    
                    print("Got Twitter Code: \(code)")
                    
                    // exchange the code for a permanent access token (PAT)
                    SocialAuthManager.shared.exchangeTwitterCodeForToken(code: code) { result in
                        DispatchQueue.main.async {
                            // dispatch to main thread to update UI to update db and change color
                            switch result {
                            case .success(let token):
                                Task {
                                    await SupabaseManager.shared.saveSocialToken(platform: "twitter", token: token)
                                    self.markButtonAsConnected(self.twitterButton)
                                    
                                    self.handleSuccessfulLogin()
                                }
                                
                            case .failure(let error):
                                print("Token Exchange Failed: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }

        
        self.webAuthSession?.presentationContextProvider = self
        // true if we want to force the login screen to appear every time
        // false if want it to remember
        self.webAuthSession?.prefersEphemeralWebBrowserSession = true
        self.webAuthSession?.start()
    }

    // MARK: - Instagram Action
    @IBAction func didTapInstagram(_ sender: UIButton) {
        print("Starting Instagram Auth...")
        let authURL = SocialAuthManager.shared.getInstagramAuthURL()
        guard let url = URL(string: authURL) else { return }

        self.webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "https") { [weak self] callbackURL, error in
                
                guard let self = self else { return }
                if let error = error { print("Auth Failed: \(error.localizedDescription)"); return }
                
                // Intercept the redirect to handleapp.com
                if let callbackURL = callbackURL,
                   callbackURL.absoluteString.starts(with: "https://handleapp.com/auth/") {
                    

                    if let token = self.getQueryStringParameter(url: callbackURL.absoluteString.replacingOccurrences(of: "#", with: "?"), param: "access_token") {
                         
                         print("INSTAGRAM TOKEN SECURED: \(token)")
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
        print("Starting LinkedIn Auth...")
        
        let authURL = SocialAuthManager.shared.getLinkedInAuthURL()
        guard let url = URL(string: a   uthURL) else { return }
        
        self.webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "https") { [weak self] callbackURL, error in
                
                guard let self = self else { return }
                if let error = error { return }
                
                //Intercept the redirect by checking the string
                if let callbackURL = callbackURL,
                   callbackURL.absoluteString.starts(with: "https://handleapp.com/auth/") {
                    
                    print("Intercepted LinkedIn HTTPS Callback!")
                    
                    // Extract the code from the intercepted URL
                    if let code = self.getQueryStringParameter(url: callbackURL.absoluteString, param: "code") {
                        
                        SocialAuthManager.shared.exchangeLinkedInCodeForToken(code: code) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let token):
                                    Task {
                                        await SupabaseManager.shared.saveSocialToken(platform: "linkedin", token: token)

                                        self.handleSuccessfulLogin()
                                    }
                                case .failure(let error):
                                    print("LinkedIn Token Exchange Failed: \(error.localizedDescription)")
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
            // wait 0.5 s and then segue back to analytics screen
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
