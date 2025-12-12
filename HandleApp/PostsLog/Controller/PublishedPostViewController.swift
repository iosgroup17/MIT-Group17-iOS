//
//  PublishedPostViewController.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 27/11/25.
//

import UIKit

// ⚠️ ASSUMPTION: You must define your Post struct and the loadPublishedPosts function
// somewhere in your project. Post objects must have a 'platformName' property (String).

class PublishedPostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    
    // MARK: - IBOutlets
    // ⚠️ CRITICAL: Ensure these are connected in the Storyboard!
    @IBOutlet weak var publishedTableView: UITableView!
    @IBOutlet weak var filterStackView: UIStackView!

    // MARK: - Data Properties
    var publishedPosts: [Post] = {
        do {
            return try Post.loadPublishedPosts(from: "Posts_data")
        } catch {
            print("FATAL ERROR: Could not load published posts. Details: \(error)")
            return []
        }
    }()
    var currentTimeFilter: String = "All"
    @IBAction func filerButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "View Activity From", message: nil, preferredStyle: .actionSheet)
                    
                    let timePeriods = ["All", "Last 7 Days", "Last 30 Days"]
                    
                    for period in timePeriods {
                        
                        let isSelected = (period == self.currentTimeFilter)
                        let displayTitle = isSelected ? "✓ \(period)" : period
                        
                        let action = UIAlertAction(title: displayTitle, style: .default) { [weak self] _ in
                            // Use the base period string for filtering
                            self?.filterPostsByTime(timePeriod: period)
                        }
                        
                        alertController.addAction(action)
                    }
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    
                    // iPad Support: Anchor to the bar button item
                    if let popover = alertController.popoverPresentationController {
                        popover.barButtonItem = sender as! UIBarButtonItem // Use the sender (the new filter button)
                        popover.delegate = self // Since PublishedPostViewController conforms to UITableViewDelegate/DataSource,
                                                // it should also conform to UIPopoverPresentationControllerDelegate if needed for popovers.
                        popover.permittedArrowDirections = .up
                    }
                    
                    present(alertController, animated: true, completion: nil)
    }
    func getDate(daysAgo: Int) -> Date {
            return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        }
    var displayedPosts: [Post] = []
    func filterPostsByTime(timePeriod: String) {
            self.currentTimeFilter = timePeriod // Update the state
            
            // 1. Start with the current platform-filtered posts
            var postsToFilter = publishedPosts
            if currentPlatformFilter != "All" {
                postsToFilter = publishedPosts.filter { $0.platformName == currentPlatformFilter }
            }
            
            // 2. Apply time filtering
            switch timePeriod {
            case "All Time":
                displayedPosts = postsToFilter
            case "Last 7 Days":
                let date7DaysAgo = getDate(daysAgo: 7)
                displayedPosts = postsToFilter.filter { post in
                    // ⚠️ ASSUMPTION: Post has a 'datePublished' property
                    return post.date! >= date7DaysAgo
                }
            case "Last 30 Days":
                let date30DaysAgo = getDate(daysAgo: 30)
                displayedPosts = postsToFilter.filter { post in
                    // ⚠️ ASSUMPTION: Post has a 'datePublished' property
                    return post.date! >= date30DaysAgo
                }
            default:
                displayedPosts = postsToFilter
            }

            publishedTableView.reloadData()
        }
    // Tracks the active filter's string value, triggering UI and data updates.
    var currentPlatformFilter: String = "All" {
        didSet {
            // This runs whenever the filter changes
            updateCapsuleAppearance()
            filterPublishedPosts(by: currentPlatformFilter)
        }
    }
    
    // For cell expansion/collapse logic
    var expandedPost: String? = nil
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Set up Table View delegates
        self.publishedTableView.delegate = self
        self.publishedTableView.dataSource = self
        
        // 2. Initialize displayedPosts (will be fully set in viewDidAppear)
        displayedPosts = publishedPosts
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 3. FINAL FIX: Set the filter state *after* the view is loaded to ensure outlets are ready.
        // This triggers the didSet, running the initial filtering and styling.
        currentPlatformFilter = "All"
        
        // Ensure table view reloads with the initial "All" data.
        publishedTableView.reloadData()
    }

    // MARK: - Action Methods (USING TAGS)
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        let tag = sender.tag
        var selectedPlatform: String?
        
        // ⚠️ CRITICAL: Ensure these tags match the tags set on your Storyboard buttons (1, 2, 3, 4)
        switch tag {
        case 1:
            selectedPlatform = "All"
        case 2:
            selectedPlatform = "Instagram"
        case 3:
            selectedPlatform = "LinkedIn"
        case 4:
            selectedPlatform = "X"
        default:
            print("ERROR: Unknown button tag: \(tag)")
            return
        }
        
        // Use selectedPlatform here
        guard let platform = selectedPlatform else { return }
        
        print("ACTION: Tag \(tag) selected. Platform: \(platform)")

        if platform != currentPlatformFilter {
            // Setting this property triggers the didSet block, which handles the filtering/styling
            currentPlatformFilter = platform
        }
    }

    // MARK: - Filtering and UI Update Logic
    
    func filterPublishedPosts(by platform: String) {
        // Guard against running before the View/Outlets are ready (for early didSet call)
        guard isViewLoaded else { return }

        if platform == "All" {
            displayedPosts = publishedPosts
        } else {
            // Filter posts where the platformName matches the selected capsule string
            displayedPosts = publishedPosts.filter { post in
                return post.platformName == platform
            }
        }

        publishedTableView.reloadData()
    }
    
    func updateCapsuleAppearance() {
        // Retrieve the button's title (using the visual text for comparison/display)
        for case let button as UIButton in filterStackView.arrangedSubviews {
            guard let platform = button.title(for: .normal) else { continue }
            
            let isSelected = (platform == currentPlatformFilter)
            
            // Apply capsule styling based on selected state
            button.layer.cornerRadius = 14.0
            button.backgroundColor = isSelected ? UIColor.systemTeal.withAlphaComponent(0.25) : UIColor.systemGray5
            button.layer.borderWidth = isSelected ? 1.0 : 0.0
            button.layer.borderColor = isSelected ? UIColor.systemTeal.cgColor : UIColor.clear.cgColor
            button.setTitleColor(.black, for: .normal)
            
            
        }
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedPosts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // ⚠️ CRITICAL: Ensure "published_cell" matches the Storyboard cell identifier
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "published_cell", for: indexPath) as? PublishedPostTableViewCell else {
            fatalError("Could not dequeue PublishedPostTableViewCell")
        }

        let post = displayedPosts[indexPath.row]
        let isExpanded = (expandedPost == post.text)

        // Assuming PublishedPostTableViewCell has a configure method
        cell.configure(with: post, isExpanded: isExpanded)

        return cell
    }

    // MARK: - Table view delegate (Cell Expansion Logic)

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let post = displayedPosts[indexPath.row]
        let baseHeight: CGFloat = 60
        let analyticsHeight: CGFloat = 100
        let padding: CGFloat = 20

        if expandedPost == post.text {
            return baseHeight + analyticsHeight + padding
        } else {
            return baseHeight
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedPost = displayedPosts[indexPath.row]
        let postText = selectedPost.text

        let previousExpanded = expandedPost

        if expandedPost == postText {
            expandedPost = nil
        } else {
            expandedPost = postText
        }
        
        var indexPathsToReload = [indexPath]
        
        if let previous = previousExpanded, previous != postText,
           let previousIndex = displayedPosts.firstIndex(where: { $0.text == previous }) {
            
            indexPathsToReload.append(IndexPath(row: previousIndex, section: 0))
        }

        tableView.beginUpdates()
        tableView.reloadRows(at: indexPathsToReload, with: .automatic)
        tableView.endUpdates()
        
        if expandedPost == postText {
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
}
