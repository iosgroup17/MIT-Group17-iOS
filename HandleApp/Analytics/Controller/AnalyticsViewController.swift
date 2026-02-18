import UIKit
import Supabase
import PostgREST
import SwiftUI // Required for the Graph

// MARK: - Animation Helper
extension UIView {
    static func animateAsync(duration: TimeInterval, delay: TimeInterval = 0, options: UIView.AnimationOptions = [], animations: @escaping () -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations) { finished in
                continuation.resume(returning: finished)
            }
        }
    }
}

class AnalyticsViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var handleScoreLabel: UILabel!
    @IBOutlet weak var weeksStreakLabel: UILabel!
    @IBOutlet weak var xPostsLabel: UILabel!
    @IBOutlet weak var instaPostsLabel: UILabel!
    @IBOutlet weak var linkedinPostsLabel: UILabel!
    @IBOutlet weak var scoreArrowImage: UIImageView!
    @IBOutlet weak var scoreDifferenceLabel: UILabel!
    
    // Stat Cards
    @IBOutlet weak var totalEngagementLabel: UILabel!
    @IBOutlet weak var topPlatformLabel: UILabel!
    @IBOutlet weak var topPlatformImageView: UIImageView!
    @IBOutlet weak var avgImpactLabel: UILabel!
    
    // Graph Container
    @IBOutlet weak var graphContainerView: UIView!
    
    // Loader
    let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationItem.backButtonTitle = ""
        
        setupDesign()
        setupLinkButton()
        setupData()
        setupGraph()
        
        // Auto-refresh
        Task {
            await SupabaseManager.shared.autoUpdateAnalytics()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
    }

    // MARK: - Setup UI
    func setupDesign() {
        if activityIndicator.superview == nil {
            activityIndicator.center = view.center
            activityIndicator.hidesWhenStopped = true
            view.addSubview(activityIndicator)
        }
        self.view.tintColor = UIColor.systemTeal
    }
    
    func setupLinkButton() {
        Task {
            let connected = await SupabaseManager.shared.fetchConnectedPlatforms()
            DispatchQueue.main.async {
                let linkButton = UIBarButtonItem(
                    image: UIImage(systemName: "link"),
                    style: .plain,
                    target: self,
                    action: #selector(self.didTapLinkButton)
                )
                // Grey out if full, but keep tappable
                linkButton.tintColor = (connected.count >= 3) ? .systemGray : self.view.tintColor
                self.navigationItem.rightBarButtonItem = linkButton
            }
        }
    }
    
    // MARK: - Data Fetching
    func setupData() {
        guard let userId = SupabaseManager.shared.client.auth.currentSession?.user.id else { return }
        
        if handleScoreLabel.text == "---" { activityIndicator.startAnimating() }

        Task {
            // 1. Fetch Analytics Data
            async let analyticsTask: UserAnalytics = SupabaseManager.shared.client
                .from("user_analytics").select().eq("user_id", value: userId).single().execute().value
            
            // 2. Fetch Active Connections (To avoid stale data)
            async let connectionsTask: [SocialConnection] = SupabaseManager.shared.client
                .from("social_connections").select().eq("user_id", value: userId).execute().value
            
            do {
                let (analytics, connections) = try await (analyticsTask, connectionsTask)
                let connectedPlatforms = Set(connections.map { $0.platform })
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    // Pass BOTH to the update function
                    self.updateLabels(with: analytics, connected: connectedPlatforms)
                }
            } catch {
                print("Error loading analytics: \(error)")
                DispatchQueue.main.async { self.activityIndicator.stopAnimating() }
            }
        }
    }
    
    // MARK: - Smart Graph Setup
    func setupGraph() {
        guard let container = self.graphContainerView else { return }

        Task {
            let metrics = await SupabaseManager.shared.fetchDailyAnalytics()
            
            DispatchQueue.main.async {
                // 1. Clear previous attempts
                container.subviews.forEach { $0.removeFromSuperview() }
                self.children.forEach { if $0 is UIHostingController<EngagementChartView> { $0.removeFromParent() } }
                
                if metrics.isEmpty { return }
                
                // 2. Setup Hosting Controller
                let chartView = EngagementChartView(metrics: metrics)
                let hostingController = UIHostingController(rootView: chartView)
                
                self.addChild(hostingController)
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false // 🛑 CRITICAL
                hostingController.view.backgroundColor = .clear
                
                container.addSubview(hostingController.view)
                
                // 3. FORCE constraints so it can NEVER overflow the container
                NSLayoutConstraint.activate([
                    hostingController.view.topAnchor.constraint(equalTo: container.topAnchor),
                    hostingController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    hostingController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    hostingController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
                ])
                
                hostingController.didMove(toParent: self)
                container.layoutIfNeeded() // Force immediate layout
            }
        }
    }

    // MARK: - UI Updates (The Smart Logic)
    func updateLabels(with data: UserAnalytics, connected: Set<String>) {
        var totalScore = 0
        var platformCount = 0
        var totalInteractions = 0
        
        var maxEng = -1
        var topPlatformName = "-"
        var topPlatformIcon = UIImage(systemName: "questionmark.circle")
        
        var totalAvg = 0
        var avgCount = 0
        
        // --- SMART LOGIC: Only count if connected! ---
        
        // Instagram
        if connected.contains("instagram") {
            if let iScore = data.insta_score { totalScore += iScore; platformCount += 1 }
            let eng = data.insta_engagement ?? 0
            totalInteractions += eng
            
            if eng > maxEng { maxEng = eng; topPlatformName = "Instagram"; topPlatformIcon = UIImage(named: "icon-instagram") }
            if let iAvg = data.insta_avg_engagement, iAvg > 0 { totalAvg += iAvg; avgCount += 1 }
            
            instaPostsLabel.text = "\(data.insta_post_count ?? 0)"
        } else {
            // Explicitly clear stale data if disconnected
            instaPostsLabel.text = "-"
        }
        
        // LinkedIn
        if connected.contains("linkedin") {
            if let lScore = data.linkedin_score { totalScore += lScore; platformCount += 1 }
            let eng = data.linkedin_engagement ?? 0
            totalInteractions += eng
            
            if eng > maxEng { maxEng = eng; topPlatformName = "LinkedIn"; topPlatformIcon = UIImage(named: "icon-linkedin") }
            if let lAvg = data.linkedin_avg_engagement, lAvg > 0 { totalAvg += lAvg; avgCount += 1 }
            
            linkedinPostsLabel.text = "\(data.linkedin_post_count ?? 0)"
        } else {
            linkedinPostsLabel.text = "-"
        }
        
        // Twitter
        if connected.contains("twitter") {
            if let xScore = data.x_score { totalScore += xScore; platformCount += 1 }
            let eng = data.x_engagement ?? 0
            totalInteractions += eng
            
            if eng > maxEng { maxEng = eng; topPlatformName = "X (Twitter)"; topPlatformIcon = UIImage(named: "icon-x") }
            if let xAvg = data.x_avg_engagement, xAvg > 0 { totalAvg += xAvg; avgCount += 1 }
            
            xPostsLabel.text = "\(data.x_post_count ?? 0)"
        } else {
            xPostsLabel.text = "-"
        }
        
        // 1. MASTER SCORE
        let finalScore = platformCount > 0 ? (totalScore / platformCount) : 0
        animateScore(to: finalScore)
        
        // 2. GREEN/RED ARROW
        let prevScore = data.previous_handle_score ?? 0
        let diff = finalScore - prevScore
        
        if diff > 0 {
            scoreDifferenceLabel.text = "\(diff)"
            scoreDifferenceLabel.textColor = .systemGreen
            scoreArrowImage.image = UIImage(systemName: "arrow.up")
            scoreArrowImage.tintColor = .systemGreen
        } else if diff < 0 {
            scoreDifferenceLabel.text = "\(abs(diff))"
            scoreDifferenceLabel.textColor = .systemRed
            scoreArrowImage.image = UIImage(systemName: "arrow.down")
            scoreArrowImage.tintColor = .systemRed
        } else {
            scoreDifferenceLabel.text = "-"
            scoreDifferenceLabel.textColor = .systemGray
            scoreArrowImage.image = UIImage(systemName: "minus")
            scoreArrowImage.tintColor = .systemGray
        }
        
        // 3. STAT CARDS
        func formatNumber(_ n: Int) -> String {
            if n >= 1000 { return String(format: "%.1fk", Double(n)/1000.0) }
            return "\(n)"
        }
        
        if let label = totalEngagementLabel { label.text = formatNumber(totalInteractions) }
        if let label = topPlatformLabel { label.text = topPlatformName }
        if let img = topPlatformImageView { img.image = topPlatformIcon }
        
        let finalAvg = avgCount > 0 ? (totalAvg / avgCount) : 0
        if let label = avgImpactLabel { label.text = formatNumber(finalAvg) }
        
        // 4. STREAK
        weeksStreakLabel.text = "\(data.consistency_weeks)"
    }
    
    // MARK: - Actions & Animations
    @objc func didTapLinkButton() {
        let storyboard = UIStoryboard(name: "Analytics", bundle: nil)
        if let authVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController {
            authVC.isManageMode = true
            authVC.modalPresentationStyle = .pageSheet
            if let sheet = authVC.sheetPresentationController { sheet.detents = [.large()] }
            self.present(authVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapHandleScoreInfo(_ sender: Any) {
        let alert = UIAlertController(title: "Handle Score", message: "Your score is a weighted engagement metric:\n\nScore = ((Likes + 2×Comments + 3×Reposts) / Impressions) × 100", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        self.present(alert, animated: true)
    }
    
    func animateScore(to score: Int) {
        let duration: Double = 1.5
        let startValue = 0
        let endValue = score
        let steps = 50
        let stepDuration = duration / Double(steps)
        var currentStep = 0
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            let value = Int(Double(startValue) + (Double(endValue - startValue) * (Double(currentStep) / Double(steps))))
            self.handleScoreLabel.text = "\(value)"
            if currentStep >= steps {
                timer.invalidate()
                self.handleScoreLabel.text = "\(endValue)"
            }
        }
    }
    
    // Suggestions Logic
    @IBAction func didTapDismissSuggestion(_ sender: UIButton) {
        guard let cardView = sender.superview else { return }
        UIView.animate(withDuration: 0.3) { cardView.isHidden = true; cardView.alpha = 0 }
        showToast(message: "Suggestion Removed", isSuccess: false)
    }
    @IBAction func didTapApplySuggestion(_ sender: UITapGestureRecognizer) {
        guard let cardView = sender.view else { return }
        UIView.animate(withDuration: 0.3) { cardView.isHidden = true; cardView.alpha = 0 }
        showToast(message: "Applying Suggestion...", isSuccess: true)
    }
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
            _ = await UIView.animateAsync(duration: 0.3) { toastView.alpha = 1.0; toastView.frame.origin.y = 100 }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            _ = await UIView.animateAsync(duration: 0.3) { toastView.alpha = 0.0; toastView.frame.origin.y = 60 }
            toastView.removeFromSuperview()
        }
    }
}
