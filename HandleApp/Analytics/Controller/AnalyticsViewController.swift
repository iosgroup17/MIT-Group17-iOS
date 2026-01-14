import UIKit

// MARK: - Modern Animation Helper
extension UIView {
    // A helper to perform UIView animations using Swift Concurrency (async/await)
    static func animateAsync(duration: TimeInterval, delay: TimeInterval = 0, options: UIView.AnimationOptions = [], animations: @escaping () -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations) { finished in
                continuation.resume(returning: finished)
            }
        }
    }
}

class AnalyticsViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationItem.backButtonTitle = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDesign()
        setupData()
            
        self.navigationItem.hidesBackButton = true

        let linkButton = UIBarButtonItem(
            image: UIImage(systemName: "link"),
            primaryAction: UIAction { [weak self] _ in
                self?.manageConnections()
            }
        )
        self.navigationItem.rightBarButtonItem = linkButton
    }
   
    func manageConnections() {
        let storyboard = UIStoryboard(name: "Analytics", bundle: nil)
        if let authVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController {
            authVC.modalPresentationStyle = .pageSheet
            self.present(authVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapHandleScoreInfo(_ sender: Any) {
        let alert = UIAlertController(
            title: "What is Handle Score?",
            message: "Your Handle Score is calculated based on your posting consistency and growth.\n\nA score above 5% indicates healthy growth!\n\nIt’s calculated using the formula: Handle Rate (%) = ((Likes + 2 × Comments + 3 × Reposts) ÷ Impressions) × 100",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func didTapDismissSuggestion(_ sender: UIButton) {
        guard let cardView = sender.superview else { return }

        UIView.animate(withDuration: 0.3) {
            cardView.isHidden = true
            cardView.alpha = 0
        }
        showToast(message: "Suggestion Removed", isSuccess: false)
    }
    
    @IBAction func didTapApplySuggestion(_ sender: UITapGestureRecognizer) {
        guard let cardView = sender.view else { return }
        
        UIView.animate(withDuration: 0.3) {
            cardView.isHidden = true
            cardView.alpha = 0
        }
        showToast(message: "Applying Suggestion...", isSuccess: true)
    }
    
    // MARK: - Setup Functions
    func setupDesign() {
        self.view.tintColor = UIColor.systemTeal
    }

    func setupData() {
        print("Data setup complete")
    }
    
    // MARK: - Modern Toast Logic with Concurrency
    func showToast(message: String, isSuccess: Bool) {

        let toastView = UIView()
        toastView.backgroundColor = isSuccess ? .systemGreen : .systemRed
        toastView.alpha = 0.0
        toastView.layer.cornerRadius = 20
        
        let label = UILabel()
        label.text = (isSuccess ? "✓ " : "✕ ") + message
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        
        toastView.addSubview(label)
        self.view.addSubview(toastView)
        
        let screenWidth = self.view.frame.width
        toastView.frame = CGRect(x: (screenWidth - 200)/2, y: 60, width: 200, height: 40)
        label.frame = toastView.bounds


        Task {
            _ = await UIView.animateAsync(duration: 0.3) {
                toastView.alpha = 1.0
                toastView.frame.origin.y = 100
            }
            

            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            _ = await UIView.animateAsync(duration: 0.3) {
                toastView.alpha = 0.0
                toastView.frame.origin.y = 60
            }
            
            toastView.removeFromSuperview()
        }
    }
}
