import UIKit
import AuthenticationServices
import Supabase
import PostgREST

class AuthViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {

    // MARK: - Outlets
    @IBOutlet weak var twitterButton: UIButton!
    @IBOutlet weak var linkedInButton: UIButton!
    @IBOutlet weak var instagramButton: UIButton!
    @IBOutlet weak var skipForNowButton: UIButton!
    
    // Variables
    var webAuthSession: ASWebAuthenticationSession?
    var connectedPlatforms: Set<String> = []
    
    // Logic Flags
    var isManageMode = false
    var onCompletion: ((Bool) -> Void)?
    
    // prevents double navigation
    private var hasNavigated = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        Task {
            await SupabaseManager.shared.ensureAnonymousSession()
            self.checkConnections()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset flag when view appears
        checkConnections()
    }
    
    // MARK: - Connection Check Logic
    func checkConnections() {
        Task {
            let list = await SupabaseManager.shared.fetchConnectedPlatforms()
            self.connectedPlatforms = Set(list)
            
            DispatchQueue.main.async {
                self.updateButtonVisuals(platform: "instagram", button: self.instagramButton)
                self.updateButtonVisuals(platform: "twitter", button: self.twitterButton)
                self.updateButtonVisuals(platform: "linkedin", button: self.linkedInButton)
                
                // Only Auto-Navigate if 3/3 AND not in Manage Mode AND haven't navigated yet
                if !self.isManageMode && list.count >= 3 && !self.hasNavigated {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.finishAuthFlow(success: true)
                    }
                }
            }
        }
    }
    
    func finishAuthFlow(success: Bool) {
            // if navigated already do nothing -> this prevents double nav
            if hasNavigated { return }
            hasNavigated = true
            
            onCompletion?(success)
            
            if let presentingVC = self.presentingViewController {
                self.dismiss(animated: true) {
                    (presentingVC as? AnalyticsViewController)?.viewWillAppear(true)
                }
            } else {
                self.performSegue(withIdentifier: "goToAnalytics", sender: self)
            }
        }

    // MARK: - Actions
    @IBAction func didTapInstagram(_ sender: UIButton) { handlePlatformToggle(platform: "instagram", button: sender) }
    @IBAction func didTapTwitter(_ sender: UIButton) { handlePlatformToggle(platform: "twitter", button: sender) }
    @IBAction func didTapLinkedIn(_ sender: UIButton) { handlePlatformToggle(platform: "linkedin", button: sender) }
    
    @IBAction func didTapSkip(_ sender: UIButton) {
        finishAuthFlow(success: true)
    }

    // MARK: - Toggle Logic
    func handlePlatformToggle(platform: String, button: UIButton) {
        if connectedPlatforms.contains(platform) {
            // DISCONNECT
            let alert = UIAlertController(title: "Disconnect \(platform.capitalized)?", message: "Stop tracking stats?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Disconnect", style: .destructive) { _ in
                self.toggleButtonLoading(button: button, isLoading: true)
                Task {
                    _ = await SupabaseManager.shared.disconnectSocial(platform: platform)
                    self.connectedPlatforms.remove(platform)
                    DispatchQueue.main.async {
                        self.toggleButtonLoading(button: button, isLoading: false)
                        button.backgroundColor = .clear
                    }
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        } else {
            //connect platforms
            if platform == "instagram" { showConnectInstagramAlert(button) }
            if platform == "twitter" { showConnectTwitterAlert(button) }
            if platform == "linkedin" { showConnectLinkedInAlert(button) }
        }
    }
    
    // MARK: - Loader Helper
    func toggleButtonLoading(button: UIButton, isLoading: Bool) {
        if isLoading {
            button.setTitle("", for: .normal)
            button.isUserInteractionEnabled = false
            if button.viewWithTag(999) == nil {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.color = .label
                spinner.tag = 999
                spinner.translatesAutoresizingMaskIntoConstraints = false
                button.addSubview(spinner)
                NSLayoutConstraint.activate([
                    spinner.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                    spinner.centerYAnchor.constraint(equalTo: button.centerYAnchor)
                ])
                spinner.startAnimating()
            }
        } else {
            if let spinner = button.viewWithTag(999) as? UIActivityIndicatorView {
                spinner.stopAnimating()
                spinner.removeFromSuperview()
            }
            button.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - UI Helpers
    func updateButtonVisuals(platform: String, button: UIButton) {
        if connectedPlatforms.contains(platform) {
            button.backgroundColor = .systemGray5
            button.setTitleColor(.systemGray, for: .normal)
            button.setTitle("\(platform.capitalized) Connected ✓", for: .normal)
        }
    }

    func showConnectInstagramAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: "Connect Instagram", message: "Enter username (no @)", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "username" }
        alert.addAction(UIAlertAction(title: "Connect", style: .default) { _ in
            guard let handle = alert.textFields?.first?.text, !handle.isEmpty else { return }
            self.performConnect(platform: "instagram", handle: handle, button: sender)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func showConnectTwitterAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: "Connect X (Twitter)", message: "Enter username (e.g. elonmusk)", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "username" }
        alert.addAction(UIAlertAction(title: "Connect", style: .default) { _ in
            guard let handle = alert.textFields?.first?.text, !handle.isEmpty else { return }
            self.performConnect(platform: "twitter", handle: handle, button: sender)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func showConnectLinkedInAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: "Connect LinkedIn", message: "Enter username (from profile URL)", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "username" }
        alert.addAction(UIAlertAction(title: "Connect", style: .default) { _ in
            guard let handle = alert.textFields?.first?.text, !handle.isEmpty else { return }
            self.performConnect(platform: "linkedin", handle: handle, button: sender)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func performConnect(platform: String, handle: String, button: UIButton) {
        toggleButtonLoading(button: button, isLoading: true)
        Task {
            await SupabaseManager.shared.saveSocialHandle(platform: platform, handle: handle)
            var score = 0
            if platform == "instagram" { score = await SupabaseManager.shared.runInstaScoreCalculation(handle: handle) }
            if platform == "twitter" { score = await SupabaseManager.shared.runTwitterScoreCalculation(handle: handle) }
            if platform == "linkedin" { score = await SupabaseManager.shared.runLinkedInScoreCalculation(handle: handle) }
            
            self.connectedPlatforms.insert(platform)
            DispatchQueue.main.async {
                self.toggleButtonLoading(button: button, isLoading: false)
                self.updateButtonVisuals(platform: platform, button: button)
                self.checkConnections()
            }
        }
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window!
    }
}
