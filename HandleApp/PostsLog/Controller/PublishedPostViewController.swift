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

    
    var publishedPosts: [Post] = []
    var displayedPosts: [Post] = []
    var currentTimeFilter: String = "All"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let imageNib = UINib(nibName: "PublishedPostImageTableViewCell", bundle: nil)
            publishedTableView.register(imageNib, forCellReuseIdentifier: "ImagePublishedCell")
           
        let textNib = UINib(nibName: "PublishedPostTextTableViewCell", bundle: nil)
            publishedTableView.register(textNib, forCellReuseIdentifier: "TextPublishedCell")
        self.publishedTableView.delegate = self
        self.publishedTableView.dataSource = self
        displayedPosts = publishedPosts
        fetchData()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentPlatformFilter = "All"
        publishedTableView.reloadData()
    }
    func fetchData() {
        Task {
            // 1. Fetch Master List
            let allPosts = await SupabaseManager.shared.fetchUserPosts()
            
            // 2. Use Extension to Filter
            self.publishedPosts = Post.loadPublishedPosts(from: allPosts)
            
            await MainActor.run {
                self.applyFilters() // This will update 'displayedPosts'
                self.publishedTableView.reloadData()
            }
        }
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
            applyFilters()
        }
    }
    
    func applyFilters() {
        var filtered = publishedPosts

        // 1. Filter by Platform
        if currentPlatformFilter != "All" {
            filtered = filtered.filter { $0.platformName == currentPlatformFilter }
        }

        // 2. Filter by Time
        if currentTimeFilter != "All" {
            let daysAgo = currentTimeFilter == "Last 7 Days" ? 7 : 30
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            filtered = filtered.filter { post in
                guard let publishDate = post.publishedAt else { return false }
                return publishDate >= cutoffDate
            }
        }

        self.displayedPosts = filtered
        self.publishedTableView.reloadData()
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
    @IBAction func filerButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "View Activity From", message: nil, preferredStyle: .actionSheet)
        
        let timePeriods = ["All", "Last 7 Days", "Last 30 Days"]
        
        for period in timePeriods {
            let isSelected = (period == self.currentTimeFilter)
            let displayTitle = isSelected ? "✓ \(period)" : period
            
            let action = UIAlertAction(title: displayTitle, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                // 1. Update the state
                self.currentTimeFilter = period
                
                // 2. Trigger the consolidated Supabase filter logic
                self.applyFilters()
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        // 3. iPad Popover Support
        if let popover = alertController.popoverPresentationController {
            popover.barButtonItem = sender
            popover.permittedArrowDirections = .up
        }
        
        present(alertController, animated: true)
    }

    func getDate(daysAgo: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    }

    

    //Table View
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedPosts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
        let post = displayedPosts[indexPath.row]
        let hasImages = post.imageNames?.isEmpty == false

        // 3. Dequeue and configure
        if hasImages {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImagePublishedCell", for: indexPath) as! PublishedPostImageTableViewCell
            cell.configure(with: post)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextPublishedCell", for: indexPath) as! PublishedPostTextTableViewCell
            cell.configure(with: post)
            return cell
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            // Automatically calculate height based on Autolayout constraints in the cell
            return UITableView.automaticDimension
        }
        
        // Optional: Provide an estimated height for performance
        func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
            return 150
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // Just deselect the row, no expansion logic needed anymore
            tableView.deselectRow(at: indexPath, animated: true)
        }
}
