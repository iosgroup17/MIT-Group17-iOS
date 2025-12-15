//
//  PublishedPostViewController.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 27/11/25.
//

import UIKit



class PublishedPostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var publishedTableView: UITableView!
    @IBOutlet weak var filterStackView: UIStackView!

    
    var publishedPosts: [Post] = {
        do {
            return try Post.loadPublishedPosts(from: "Posts_data")
        } catch {
            print("FATAL ERROR: Could not load published posts. Details: \(error)")
            return []
        }
    }()
    var currentTimeFilter: String = "All"
    var displayedPosts: [Post] = []
    var expandedPost: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.publishedTableView.delegate = self
        self.publishedTableView.dataSource = self
        displayedPosts = publishedPosts
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentPlatformFilter = "All"
        publishedTableView.reloadData()
    }

    //Platform wise filter
    @IBAction func buttonTapped(_ sender: UIButton) {
        let tag = sender.tag
        var selectedPlatform: String?

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
        guard let platform = selectedPlatform else { return }
        
        print("ACTION: Tag \(tag) selected. Platform: \(platform)")

        if platform != currentPlatformFilter {
            currentPlatformFilter = platform
        }
    }

    var currentPlatformFilter: String = "All" {
        didSet {
            updateCapsuleAppearance()
            filterPublishedPosts(by: currentPlatformFilter)
        }
    }
    
    func filterPublishedPosts(by platform: String) {
        guard isViewLoaded else { return }
        if platform == "All" {
            displayedPosts = publishedPosts
        } else {
            displayedPosts = publishedPosts.filter { post in
                return post.platformName == platform
            }
        }
        publishedTableView.reloadData()
    }
    
    func updateCapsuleAppearance() {
        for case let button as UIButton in filterStackView.arrangedSubviews {
            guard let platform = button.title(for: .normal) else { continue }
            let isSelected = (platform == currentPlatformFilter)
            button.layer.cornerRadius = 14.0
            button.backgroundColor = isSelected ? UIColor.systemTeal.withAlphaComponent(0.25) : UIColor.systemGray5
            button.layer.borderWidth = isSelected ? 1.0 : 0.0
            button.layer.borderColor = isSelected ? UIColor.systemTeal.cgColor : UIColor.clear.cgColor
            button.setTitleColor(.black, for: .normal)
        }
    }
    
    //Time wise filter
    @IBAction func filerButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "View Activity From", message: nil, preferredStyle: .actionSheet)
        let timePeriods = ["All", "Last 7 Days", "Last 30 Days"]
        for period in timePeriods {
            let isSelected = (period == self.currentTimeFilter)
            let displayTitle = isSelected ? "✓ \(period)" : period
            let action = UIAlertAction(title: displayTitle, style: .default) { [weak self] _ in
                self?.filterPostsByTime(timePeriod: period)
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        if let popover = alertController.popoverPresentationController {
            popover.barButtonItem = sender as? UIBarButtonItem // Use the sender (the new filter button)
            popover.delegate = self 
            popover.permittedArrowDirections = .up
        }
        present(alertController, animated: true, completion: nil)
    }

    func getDate(daysAgo: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    }

    func filterPostsByTime(timePeriod: String) {
            self.currentTimeFilter = timePeriod
            var postsToFilter = publishedPosts
            if currentPlatformFilter != "All" {
                postsToFilter = publishedPosts.filter { $0.platformName == currentPlatformFilter }
            }
            switch timePeriod {
            case "All":
                displayedPosts = postsToFilter
            case "Last 7 Days":
                let date7DaysAgo = getDate(daysAgo: 7)
                displayedPosts = postsToFilter.filter { post in
                    return post.date! >= date7DaysAgo
                }
            case "Last 30 Days":
                let date30DaysAgo = getDate(daysAgo: 30)
                displayedPosts = postsToFilter.filter { post in
                    return post.date! >= date30DaysAgo
                }
            default:
                displayedPosts = postsToFilter
            }
            publishedTableView.reloadData()
    }

    //Table View
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedPosts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "published_cell", for: indexPath) as? PublishedPostTableViewCell else {
            fatalError("Could not dequeue PublishedPostTableViewCell")
        }

        let post = displayedPosts[indexPath.row]
        let isExpanded = (expandedPost == post.text)

        // Assuming PublishedPostTableViewCell has a configure method
        cell.configure(with: post, isExpanded: isExpanded)

        return cell
    }

    //For collapsible analytics view height constraint.
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
    
    //Analytics for selected post.
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
