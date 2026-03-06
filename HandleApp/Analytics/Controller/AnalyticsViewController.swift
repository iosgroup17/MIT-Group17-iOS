import UIKit
import Supabase
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
    
    // Best Post Card Outlets
    @IBOutlet weak var bestPostCard: UIView!
    @IBOutlet weak var bestPostPlatformImage: UIImageView!
    @IBOutlet weak var bestPostTextLabel: UILabel!
    @IBOutlet weak var bestPostMetricsStack: UIStackView!
    @IBOutlet weak var bestPostDateLabel: UILabel!
    
    // Suggestions
    @IBOutlet weak var suggestionStack: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    // Info Button
    @IBOutlet weak var infoButton: UIButton!
    // MARK: - Variables
    private var connectedPlatforms: Set<String> = []
    private var currentBestPostURL: String?
    
    // Uses your struct defined in supabase.swift
    var activeSuggestions: [Suggestion] = []

    // MARK: - Lifecycle
    // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            self.navigationItem.hidesBackButton = true
            
            // 1. RESTORE HEADING & NAVIGATION BAR
            self.title = "Analytics"
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            
            // 2. RESTORE LINK BAR BUTTON ITEM
            let linkIcon = UIImage(systemName: "link")
            let linkButton = UIBarButtonItem(image: linkIcon, style: .plain, target: self, action: #selector(openLinkPlatforms))
            self.navigationItem.rightBarButtonItem = linkButton
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(openBestPostURL))
            bestPostCard?.addGestureRecognizer(tap)
            bestPostCard?.isUserInteractionEnabled = true
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            // Ensure nav bar stays visible when returning from AuthVC
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            
            setupData()
            
            Task {
                DispatchQueue.main.async {
                    self.setupGraph()
                    self.fetchBestPost()
                }
            }
        }

    // MARK: - Data Fetching
        func setupData() {
            guard let userId = SupabaseManager.shared.client.auth.currentSession?.user.id else { return }
            
            if handleScoreLabel?.text == "---" { self.activityIndicator?.startAnimating() }
            
            // 🛑 NEW: Completely clear the Best Post UI to a default loading state
            self.bestPostTextLabel?.text = "Loading content..."
            self.bestPostDateLabel?.text = "--"
            self.bestPostPlatformImage?.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
            self.bestPostPlatformImage?.tintColor = .systemGray4
            self.bestPostMetricsStack?.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            Task {
                do {
                    async let analyticsArrayTask: [UserAnalytics] = SupabaseManager.shared.client
                        .from("user_analytics").select().eq("user_id", value: userId).execute().value
                    
                    async let connectionsTask: [SocialConnection] = SupabaseManager.shared.client
                        .from("social_connections").select().eq("user_id", value: userId).execute().value
                    
                    let (analyticsArray, connections) = try await (analyticsArrayTask, connectionsTask)
                    
                    let analytics = analyticsArray.first ?? UserAnalytics(handle_score: nil, consistency_weeks: 0, last_updated: nil, insta_score: nil, insta_post_count: nil, insta_engagement: nil, insta_avg_engagement: nil, linkedin_score: nil, linkedin_post_count: nil, linkedin_engagement: nil, linkedin_avg_engagement: nil, x_score: nil, x_post_count: nil, x_engagement: nil, x_avg_engagement: nil, previous_handle_score: nil)
                    
                    let connectedSet = Set(connections.map { $0.platform })
                    
                    DispatchQueue.main.async {
                        self.activityIndicator?.stopAnimating()
                        self.updateLabels(with: analytics, connected: connectedSet)
                        self.setupGraph()
                        self.fetchBestPost()
                        self.updateSuggestionsUI()
                    }
                } catch {
                    print("Error loading analytics: \(error)")
                    DispatchQueue.main.async { self.activityIndicator?.stopAnimating() }
                }
            }
        }
    
    
    

    // MARK: - UI Updaters
    func updateLabels(with data: UserAnalytics, connected: Set<String>) {
        self.connectedPlatforms = connected
        
        var totalScore = 0
        var platformCount = 0
        
        if connected.contains("instagram"), let s = data.insta_score {
            totalScore += s; platformCount += 1
            instaPostsLabel.text = "\(data.insta_post_count ?? 0)"
        } else {
            instaPostsLabel.text = "--"
        }
        
        if connected.contains("twitter"), let s = data.x_score {
            totalScore += s; platformCount += 1
            xPostsLabel.text = "\(data.x_post_count ?? 0)"
        } else {
            xPostsLabel.text = "--"
        }
        
        if connected.contains("linkedin"), let s = data.linkedin_score {
            totalScore += s; platformCount += 1
            linkedinPostsLabel.text = "\(data.linkedin_post_count ?? 0)"
        } else {
            linkedinPostsLabel.text = "--"
        }
        
        let finalScore = platformCount > 0 ? (totalScore / platformCount) : 0
        handleScoreLabel.text = platformCount > 0 ? "\(finalScore)" : "---"
        weeksStreakLabel.text = "\(data.consistency_weeks)"
        
        let prev = data.previous_handle_score ?? 0
        let diff = finalScore - prev
        scoreDifferenceLabel.text = "\(abs(diff))"
        scoreDifferenceLabel.textColor = diff >= 0 ? .systemGreen : .systemRed
        scoreArrowImage.image = UIImage(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
        scoreArrowImage.tintColor = diff >= 0 ? .systemGreen : .systemRed
        
        let totalEng = (connected.contains("instagram") ? (data.insta_engagement ?? 0) : 0) +
                       (connected.contains("twitter") ? (data.x_engagement ?? 0) : 0) +
                       (connected.contains("linkedin") ? (data.linkedin_engagement ?? 0) : 0)
        
        totalEngagementLabel.text = formatEngagement(totalEng)
        
        let scores = [
            ("instagram", data.insta_score ?? 0),
            ("twitter", data.x_score ?? 0),
            ("linkedin", data.linkedin_score ?? 0)
        ].filter { connected.contains($0.0) }.sorted { $0.1 > $1.1 }
        
        if let top = scores.first {
            topPlatformLabel.text = top.0.capitalized
            topPlatformImageView.image = UIImage(named: "icon-\(top.0)")
        } else {
            topPlatformLabel.text = "None"
            topPlatformImageView.image = nil
        }
        
        let totalAvg = (connected.contains("instagram") ? (data.insta_avg_engagement ?? 0) : 0) +
                       (connected.contains("twitter") ? (data.x_avg_engagement ?? 0) : 0) +
                       (connected.contains("linkedin") ? (data.linkedin_avg_engagement ?? 0) : 0)
        let finalAvg = platformCount > 0 ? totalAvg / platformCount : 0
        avgImpactLabel.text = formatEngagement(finalAvg)
    }

    // MARK: - Graph Rendering
    func setupGraph() {
        guard let userId = SupabaseManager.shared.client.auth.currentSession?.user.id else { return }
        
        Task {
            do {
                let rows: [DailyAnalyticsRow] = try await SupabaseManager.shared.client
                    .from("daily_analytics").select().eq("user_id", value: userId).execute().value
                
                let metrics = rows.map { row in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let date = formatter.date(from: row.date) ?? Date()
                    return DailyMetric(date: date, engagement: row.engagement, platform: row.platform)
                }
                
                DispatchQueue.main.async {
                    let chartView = EngagementChartView(metrics: metrics, connectedPlatforms: self.connectedPlatforms)
                    let hostingController = UIHostingController(rootView: chartView)
                    
                    self.addChild(hostingController)
                    hostingController.view.frame = self.graphContainerView.bounds
                    hostingController.view.backgroundColor = .clear
                    
                    self.graphContainerView.subviews.forEach { $0.removeFromSuperview() }
                    self.graphContainerView.addSubview(hostingController.view)
                    hostingController.didMove(toParent: self)
                }
            } catch {
                print("Graph Error: \(error)")
            }
        }
    }

    // MARK: - Best Post Logic
        func fetchBestPost() {
            guard let userId = SupabaseManager.shared.client.auth.currentSession?.user.id else { return }
            Task {
                do {
                    let posts: [BestPost] = try await SupabaseManager.shared.client
                        .from("best_posts").select().eq("user_id", value: userId).execute().value
                    
                    DispatchQueue.main.async {
                        if let post = posts.first {
                            self.currentBestPostURL = post.post_url
                            self.updateBestPostUI(with: post)
                        } else {
                            // 🛑 NEW: EMPTY STATE (No posts or no platform connected)
                            self.bestPostTextLabel?.text = "No top post found for this week."
                            self.bestPostDateLabel?.text = "--"
                            
                            // Looks for an image named "placeholder" in your Assets.xcassets
                            // Falls back to a system photo icon if "placeholder" isn't found
                            self.bestPostPlatformImage?.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
                            self.bestPostPlatformImage?.tintColor = .systemGray4
                        }
                    }
                } catch {
                    print("Best post error: \(error)")
                    DispatchQueue.main.async {
                        // 🛑 NEW: ERROR STATE
                        self.bestPostTextLabel?.text = "No top post found for this week."
                        self.bestPostDateLabel?.text = "--"
                        self.bestPostPlatformImage?.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
                        self.bestPostPlatformImage?.tintColor = .systemGray4
                    }
                }
            }
        }

        func updateBestPostUI(with post: BestPost) {
            // 🛑 NEW: Remove the gray tint so original platform colors (Twitter/LinkedIn/Insta) show properly
            bestPostPlatformImage?.tintColor = nil
            bestPostPlatformImage?.image = UIImage(named: "icon-\(post.platform.lowercased())")
            
            bestPostTextLabel?.text = post.post_text ?? "View this week's highlight..."
            
            if let dateStr = post.post_date {
                let dbFormatter = DateFormatter()
                dbFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dbFormatter.date(from: dateStr) {
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateStyle = .medium
                    bestPostDateLabel?.text = displayFormatter.string(from: date)
                }
            } else {
                bestPostDateLabel?.text = "--"
            }
            
            bestPostMetricsStack?.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            var stats: [(String, Int)] = [
                        ("Likes", post.likes),
                        ("Comments", post.comments)
                    ]
                    
                    if post.platform.lowercased() == "twitter" {
                        stats.append(("Reposts", post.shares_reposts ?? 0))
                        if let v = post.extra_metric, v > 0 { stats.append(("Views", v)) }
                    } else if post.platform.lowercased() == "linkedin" {
                        stats.append(("Shares", post.shares_reposts ?? 0))
                    } else if post.platform.lowercased() == "instagram" {
                        // 🛑 NEW: Added support to show extra metrics (Plays/Views) for Instagram!
                        if let v = post.extra_metric, v > 0 { stats.append(("Plays", v)) }
                    }
                    
                    for (label, value) in stats {
                        let metricView = createVerticalMetricStack(title: label, count: value)
                        bestPostMetricsStack?.addArrangedSubview(metricView)
                    }
        }



    @objc func openBestPostURL() {
        guard let urlStr = currentBestPostURL, let url = URL(string: urlStr) else {
            showToast(message: "Post link unavailable", isSuccess: false)
            return
        }
        UIApplication.shared.open(url)
    }

    func createVerticalMetricStack(title: String, count: Int) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        
        let countLabel = UILabel()
        countLabel.text = formatEngagement(count)
        countLabel.font = .boldSystemFont(ofSize: 14)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.textColor = .secondaryLabel
        
        stack.addArrangedSubview(countLabel)
        stack.addArrangedSubview(titleLabel)
        return stack
    }
    
    // MARK: - Programmatic Suggestions UI
    func updateSuggestionsUI() {
        suggestionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let actedCount = activeSuggestions.filter { $0.status != "pending" }.count
        if actedCount >= 2 {
            showWeeklyCompletionState()
            return
        }
        
        let pendingOnes = activeSuggestions.filter { $0.status == "pending" }
        if pendingOnes.isEmpty {
            showWeeklyCompletionState()
        } else {
            for suggestion in pendingOnes {
                guard let originalIndex = activeSuggestions.firstIndex(where: { $0.suggestion_id == suggestion.suggestion_id }) else { continue }
                
                // Build the card programmatically using YOUR AnalyticsCardView
                let cardView = AnalyticsCardView()
                
                let vStack = UIStackView()
                vStack.axis = .vertical
                vStack.spacing = 8
                vStack.translatesAutoresizingMaskIntoConstraints = false
                
                let titleLabel = UILabel()
                titleLabel.text = suggestion.title ?? "Smart Suggestion"
                titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
                
                let descLabel = UILabel()
                descLabel.text = suggestion.ai_rule ?? "No description available"
                descLabel.font = .systemFont(ofSize: 14)
                descLabel.textColor = .secondaryLabel
                descLabel.numberOfLines = 0
                
                let hStack = UIStackView()
                hStack.axis = .horizontal
                hStack.spacing = 12
                hStack.distribution = .fillEqually
                
                let applyBtn = UIButton(type: .system)
                applyBtn.setTitle("Apply", for: .normal)
                applyBtn.backgroundColor = .systemBlue
                applyBtn.setTitleColor(.white, for: .normal)
                applyBtn.layer.cornerRadius = 8
                applyBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
                applyBtn.heightAnchor.constraint(equalToConstant: 36).isActive = true
                applyBtn.tag = originalIndex
                // Notice this now uses UIButton target instead of gesture
                applyBtn.addTarget(self, action: #selector(didTapApplySuggestion(_:)), for: .touchUpInside)
                
                let removeBtn = UIButton(type: .system)
                removeBtn.setTitle("Dismiss", for: .normal)
                removeBtn.backgroundColor = .systemGray5
                removeBtn.setTitleColor(.systemRed, for: .normal)
                removeBtn.layer.cornerRadius = 8
                removeBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
                removeBtn.heightAnchor.constraint(equalToConstant: 36).isActive = true
                removeBtn.tag = originalIndex
                removeBtn.addTarget(self, action: #selector(didTapRemoveSuggestion(_:)), for: .touchUpInside)
                
                hStack.addArrangedSubview(removeBtn)
                hStack.addArrangedSubview(applyBtn)
                
                vStack.addArrangedSubview(titleLabel)
                vStack.addArrangedSubview(descLabel)
                vStack.addArrangedSubview(hStack)
                
                cardView.addSubview(vStack)
                
                // Pin inner stack to the AnalyticsCardView
                NSLayoutConstraint.activate([
                    vStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
                    vStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
                    vStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
                    vStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
                ])
                
                suggestionStack.addArrangedSubview(cardView)
            }
        }
    }
    
    private func showWeeklyCompletionState() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        let label = UILabel()
        label.text = "Good going! 🔥\nNew suggestions will load next week."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel
        
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        suggestionStack.addArrangedSubview(container)
    }

    // MARK: - Actions
    
    // MARK: - Navigation Actions
    // MARK: - Navigation Actions
        @objc func openLinkPlatforms() {
            // 🛑 FIX: Use 'self.storyboard' to automatically search the current storyboard
            // (This prevents the crash if your storyboard is named "Analytics" instead of "Main")
            guard let currentStoryboard = self.storyboard else { return }
            
            if let authVC = currentStoryboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController {
                
                // Set your specific manage mode flag
                authVC.isManageMode = true
                
                // When AuthVC finishes, reload the analytics data!
                authVC.onCompletion = { [weak self] success in
                    if success {
                        self?.setupData()
                    }
                }
                
                // Present it nicely
                let navController = UINavigationController(rootViewController: authVC)
                if let sheet = navController.sheetPresentationController {
                    sheet.detents = [.medium(), .large()] // Gives it that modern half-screen swipe up look
                }
                self.present(navController, animated: true)
                
            } else {
                // Safe fallback just in case
                print("ERROR: Could not find a View Controller with the Storyboard ID 'AuthViewController'.")
            }
        }
    
    
    @objc func didTapRemoveSuggestion(_ sender: UIButton) {
        let index = sender.tag
        guard index < activeSuggestions.count else { return }
        let suggestion = activeSuggestions[index]
        
        // Find the parent card view to hide it
        var parentView: UIView? = sender
        while parentView != nil && !(parentView is AnalyticsCardView) {
            parentView = parentView?.superview
        }
        let cardView = parentView
        
        Task {
            // Uncomment the line below to actually update the DB
            // await SupabaseManager.shared.updateSuggestionStatus(id: suggestion.suggestion_id, status: "rejected")
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    cardView?.isHidden = true
                    cardView?.alpha = 0
                }) { _ in
                    cardView?.removeFromSuperview()
                    self.activeSuggestions[index].status = "rejected"
                    self.updateSuggestionsUI() // Refresh state
                }
                self.showToast(message: "Suggestion Dismissed", isSuccess: false)
            }
        }
    }
    
    @objc func didTapApplySuggestion(_ sender: UIButton) {
        let index = sender.tag
        guard index < activeSuggestions.count else { return }
        let suggestion = activeSuggestions[index]
        
        var parentView: UIView? = sender
        while parentView != nil && !(parentView is AnalyticsCardView) {
            parentView = parentView?.superview
        }
        let cardView = parentView
        
        Task {
            // Uncomment the line below to actually update the DB
            // await SupabaseManager.shared.updateSuggestionStatus(id: suggestion.suggestion_id, status: "accepted")
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    cardView?.isHidden = true
                    cardView?.alpha = 0
                }) { _ in
                    cardView?.removeFromSuperview()
                    self.activeSuggestions[index].status = "accepted"
                    self.updateSuggestionsUI() // Refresh state
                }
                self.showToast(message: "Strategy Applied!", isSuccess: true)
            }
        }
    }

    // MARK: - Helpers
    private func formatEngagement(_ value: Int) -> String {
        let num = Double(value)
        if num >= 1_000_000 { return String(format: "%.1fM", num / 1_000_000) }
        if num >= 1_000 { return String(format: "%.1fK", num / 1_000) }
        return "\(value)"
    }
    
    // MARK: - Info Button Action
        @IBAction func infoButtonTapped(_ sender: UIButton) {
            let alert = UIAlertController(
                title: "Handle Score",
                message: "Your Handle Score is a master metric calculated based on your posting consistency and average engagement across all your connected platforms. The more you post, the higher it goes!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Got it!", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
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
