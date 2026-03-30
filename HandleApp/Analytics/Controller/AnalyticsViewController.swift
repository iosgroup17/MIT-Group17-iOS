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
    
    @IBOutlet var suggestionCards: [UIView]!
    @IBOutlet var suggestionTitles: [UILabel]!
    @IBOutlet var suggestionBodies: [UILabel]!
    
    // Info Button
    @IBOutlet weak var infoButton: UIButton!
    // MARK: - Variables
    private var connectedPlatforms: Set<String> = []
    private var currentBestPostURL: String?
    
    // Uses your struct defined in supabase.swift
    var activeSuggestions: [Suggestion] = []

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
            
            //nav bar stays visible when returning from AuthVC
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            
            setupData()
            setupSuggestions()
            
            Task {
                DispatchQueue.main.async {
                    self.setupGraph()
                    self.fetchBestPost()
                }
            }
        }
    
    func setupSuggestions() {
        Task {
            let items = await SupabaseManager.shared.fetchPendingSuggestions()
            
            DispatchQueue.main.async {
                //Save the data so the Tap Gestures can find it
                self.activeSuggestions = items
                
                self.suggestionCards.forEach { $0.isHidden = true }
                
                if items.isEmpty {
                    self.showWeeklyCompletionState()
                    return
                }
                
                for (index, item) in items.enumerated() {
                    guard index < self.suggestionCards.count else { break }
                    let card = self.suggestionCards[index]
                    card.isHidden = false
                    card.alpha = 1.0 // Ensure it's visible
                    card.tag = index
                    
                    self.suggestionTitles[index].text = item.title
                    self.suggestionBodies[index].text = item.ai_rule
                }
            }
        }
    }
    
    func updateSuggestionsUI() {
        // Hide all first, then show only what we have
        suggestionCards.forEach { $0.isHidden = true }
        
        for (index, item) in activeSuggestions.enumerated() {
            guard index < suggestionCards.count else { break }
            
            let card = suggestionCards[index]
            card.isHidden = false
            card.alpha = 1.0
            card.tag = index // Store index for the tap action
            
            suggestionTitles[index].text = item.title
            self.suggestionBodies[index].text = item.ai_rule
            
            // Minimalist style: light border, no gradients
            card.layer.borderColor = UIColor.systemGray5.cgColor
            card.layer.borderWidth = 1.0
            card.layer.cornerRadius = 12
        }
    }
    
    func loadSmartSuggestions() {
        Task {
            let items = await SupabaseManager.shared.fetchPendingSuggestions()
            self.activeSuggestions = items
            
            DispatchQueue.main.async {
                self.updateSuggestionsUI()
            }
        }
    }

    // MARK: - Data Fetching
        func setupData() {
            guard let userId = SupabaseManager.shared.client.auth.currentSession?.user.id else { return }
            
            if handleScoreLabel?.text == "---" { self.activityIndicator?.startAnimating() }
            
            // clear the Best Post UI to a default loading state
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
                            //(No posts or no platform connected)
                            self.bestPostTextLabel?.text = "No top post found for this week."
                            self.bestPostDateLabel?.text = "--"
        
                            // placeholder for best post image else system photo icon
                            self.bestPostPlatformImage?.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
                            self.bestPostPlatformImage?.tintColor = .systemGray4
                        }
                    }
                } catch {
                    print("Best post error: \(error)")
                    DispatchQueue.main.async {
                        // ERROR STATE
                        self.bestPostTextLabel?.text = "No top post found for this week."
                        self.bestPostDateLabel?.text = "--"
                        self.bestPostPlatformImage?.image = UIImage(named: "placeholder") ?? UIImage(systemName: "photo")
                        self.bestPostPlatformImage?.tintColor = .systemGray4
                    }
                }
            }
        }

        func updateBestPostUI(with post: BestPost) {
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
                        //extra metrics (Plays/Views) for Instagram
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
    
    
    private func showWeeklyCompletionState() {
        // Clear hidden cards from the stack so the stub centers correctly
        suggestionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
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
        
        // Animate the appearance of the stub
        container.alpha = 0
        suggestionStack.addArrangedSubview(container)
        UIView.animate(withDuration: 0.5) { container.alpha = 1.0 }
    }
    
    private func checkSuggestionsEmptyState(removedIndex: Int) {
        // 1. Mark the suggestion as no longer 'pending' locally
        activeSuggestions[removedIndex].status = "accepted" // or "declined"
        
        // 2. Count how many are still pending
        let remainingPending = activeSuggestions.filter { $0.status == "pending" }
        
        // 3. If zero, show your completion stub
        if remainingPending.isEmpty {
            showWeeklyCompletionState()
        }
    }

    // MARK: - Navigation Actions
        @objc func openLinkPlatforms() {
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
                
                // Present it
                let navController = UINavigationController(rootViewController: authVC)
                if let sheet = navController.sheetPresentationController {
                    sheet.detents = [.large()]
                }
                self.present(navController, animated: true)
                
            } else {
                print("ERROR: Could not find a View Controller with the Storyboard ID 'AuthViewController'.")
            }
        }
    
    
    @IBAction func didTapDismissSuggestion(_ sender: UIButton) {
        // 1. Find the parent card view that holds the tag
        guard let cardView = sender.superview else { return }
        let index = cardView.tag
        
        // 2. Safety check for array bounds
        guard index < activeSuggestions.count else { return }
        let suggestion = activeSuggestions[index]
        
        Task {
            // 3. Update Supabase
            await SupabaseManager.shared.updateSuggestionStatus(id: suggestion.suggestion_id, status: "declined")
            
            DispatchQueue.main.async {
                // 4. Animate the card away
                UIView.animate(withDuration: 0.3, animations: {
                    cardView.alpha = 0
                    cardView.isHidden = true
                }) { _ in
                    // 5. Update local state and check if all are gone
                    self.checkSuggestionsEmptyState(removedIndex: index)
                }
                self.showToast(message: "Suggestion Removed", isSuccess: false)
            }
        }
    }
    
    @IBAction func didTapApplySuggestion(_ sender: UITapGestureRecognizer) {
        guard let cardView = sender.view else { return }
        let index = cardView.tag
        guard index < activeSuggestions.count else { return }
        
        let suggestion = activeSuggestions[index]
        
        Task {
            await SupabaseManager.shared.updateSuggestionStatus(id: suggestion.suggestion_id, status: "accepted")
            
            DispatchQueue.main.async {
                // 1. Animate out
                UIView.animate(withDuration: 0.3, animations: {
                    cardView.alpha = 0
                    cardView.isHidden = true
                }) { _ in
                // 2. Remove from local array and check if empty
                    self.checkSuggestionsEmptyState(removedIndex: index)
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
