//
//  PostsViewController.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 25/11/25.
//


import UIKit

class PostsViewController: UIViewController {

    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var weekDayStackView: UIStackView!
    @IBOutlet weak var cardTableView: UIView!
    @IBOutlet weak var monthLabel: UILabel!
    
    @IBOutlet weak var shadowTableView: UIView!
    @IBOutlet weak var calendarCardView: UIView!
    @IBOutlet weak var calendarShadowView: UIView!
    @IBOutlet weak var publishedStackView: UIStackView!
    @IBOutlet weak var scheduledStackView: UIStackView!
    @IBOutlet weak var savedStackView: UIStackView!
    @IBOutlet weak var postsTableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    var todayScheduledPosts: [Post] = []
    var allPosts: [Post] = []
    var existingPostId: UUID?
    
    var currentWeekStartDate: Date = Calendar.current.startOfDay(for: Date())
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController? .hidesBarsOnSwipe = false
        
        let imageNib = UINib(nibName: "SchForTodayImageTableViewCell", bundle: nil)
            postsTableView.register(imageNib, forCellReuseIdentifier: "SchForTodayImageTableViewCell")
                    
            let textNib = UINib(nibName: "SchForTodayTableViewCell", bundle:nil)
        postsTableView.register(textNib, forCellReuseIdentifier: "SchForTodayTableViewCell")
        
        postsTableView.rowHeight = UITableView.automaticDimension
            postsTableView.estimatedRowHeight = 100
            
        let calendar = Calendar.current
        currentWeekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        setupCustomCalendar(for: currentWeekStartDate) // Pass the starting date
        
        calendarShadowView.layer.shadowColor = UIColor.black.cgColor
        calendarShadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
        calendarShadowView.layer.shadowRadius = 8
        calendarShadowView.layer.shadowOpacity = 0.1


        calendarCardView.layer.cornerRadius = 8

        //tap gesture for each stack to navigate.
        let tapSavedGesture = UITapGestureRecognizer(target: self, action: #selector(savedStackTapped))
            savedStackView.addGestureRecognizer(tapSavedGesture)
        savedStackView.isUserInteractionEnabled = true
        let tapScheduledGesture = UITapGestureRecognizer(target: self, action: #selector(scheduledStackTapped))
            scheduledStackView.addGestureRecognizer(tapScheduledGesture)
        scheduledStackView.isUserInteractionEnabled = true
        let tapPublishedGesture = UITapGestureRecognizer(target: self, action: #selector(publishedStackTapped))
            publishedStackView.addGestureRecognizer(tapPublishedGesture)
        publishedStackView.isUserInteractionEnabled = true

        applyPillShadowStyle(to: publishedStackView)
        applyPillShadowStyle(to: scheduledStackView)
        applyPillShadowStyle(to: savedStackView)
        
        

        updateTableViewHeight()
        postsTableView.dataSource = self
        postsTableView.delegate = self
        
        shadowTableView.layer.shadowColor = UIColor.black.cgColor
        shadowTableView.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowTableView.layer.shadowRadius = 8
        shadowTableView.layer.shadowOpacity = 0.1


        cardTableView.layer.cornerRadius = 16
        

    }
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            fetchData() // Refresh every time the view appears
    }
    //Fetch posts from supabase.
    func fetchData() {
        Task {
                // 1. Fetch EVERYTHING
                let fetchedPosts = await SupabaseManager.shared.fetchUserPosts()
                self.allPosts = fetchedPosts
                
                // 2. Filter locally for "Today's Schedule"
                let today = Date()
                self.todayScheduledPosts = fetchedPosts.filter { post in
                    guard post.status == .scheduled, let date = post.scheduledAt else { return false }
                    return Calendar.current.isDate(date, inSameDayAs: today)
                }
                
                await MainActor.run {
                    self.postsTableView.reloadData()
                    self.updateTableViewHeight()
                    
                    // We pass 'currentWeekStartDate' so it doesn't reset the scroll position
                    self.setupCustomCalendar(for: self.currentWeekStartDate)
                }
            }
    }
    
    //Setting up the weekly calendar
    func setupCustomCalendar(for startDate: Date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM yyyy"
            monthLabel.text = dateFormatter.string(from: startDate)
            addWeekdayLabels()
            addDateViews(startingFrom: startDate)
    }
            
    func addWeekdayLabels() {
        let daysOfWeek = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        weekDayStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let todayIndex = weekdayIndex(for: Date())
            
        for (index,day) in daysOfWeek.enumerated() {
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
            label.textColor = .systemGray
            
            let container = UIView()
            container.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -3)
            ])
            
            // Handle Selection Background
            if index == todayIndex {
                container.backgroundColor = .systemTeal.withAlphaComponent(70/255)
                container.layer.cornerRadius = 18
                container.clipsToBounds = true
                container.heightAnchor.constraint(equalToConstant: 36).isActive = true
            } else {
                container.heightAnchor.constraint(equalToConstant: 36).isActive = true
            }
            
            weekDayStackView.addArrangedSubview(label)
        }
    }
    
    func weekdayIndex(for date: Date) -> Int {
        return Calendar.current.component(.weekday, from: date) - 1
    }
    
    func addDateViews(startingFrom startDate: Date) {
        let calendar = Calendar.current
        let selectedDate = Date()
            
        dateStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
        for i in 0..<7 {
            //Actual Date object for this column
            guard let columnDate = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            
            let dateString = String(calendar.component(.day, from: columnDate))
            let isSelected = calendar.isDate(columnDate, inSameDayAs: selectedDate)
            
            //Event indicator color based on whether the post is scheduled or published.
            let statusColor = getStatusColor(for: columnDate)
                
            //Pass the color to the container creator
            let dateContainer = createDateContainer(
                date: dateString,
                isSelected: isSelected,
                indicatorColor: statusColor,
                dayIndex: i
            )
                
            dateStackView.addArrangedSubview(dateContainer)
        }
    }

    private func createDateContainer(date: String, isSelected: Bool, indicatorColor: UIColor, dayIndex: Int) -> UIView {
        let label = UILabel()
        label.text = date
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textColor = .label
            
        let container = UIView()
            container.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            // 1. Set translatesAutoresizingMaskIntoConstraints to false for the container
            container.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -3),
                
                // 2. Force the container to be a square
                container.heightAnchor.constraint(equalToConstant: 32),
                container.widthAnchor.constraint(equalToConstant: 32)
            ])

            if isSelected {
                container.backgroundColor = .systemTeal.withAlphaComponent(40/255)
                // 3. Corner radius should be half of the height/width
                container.layer.cornerRadius = 16
                container.clipsToBounds = true
                label.textColor = .systemTeal
            }
        
        // Handle Indicator Dotselected
        if indicatorColor != .clear && !isSelected {
            let indicator = UIView()
            indicator.backgroundColor = indicatorColor
            
            indicator.layer.cornerRadius = 2.5
            indicator.clipsToBounds = true
            indicator.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(indicator)
            
            NSLayoutConstraint.activate([
                indicator.widthAnchor.constraint(equalToConstant: 5),
                indicator.heightAnchor.constraint(equalToConstant: 5),
                indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                indicator.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2)
            ])
        }
            
        return container
    }

    func getStatusColor(for dateToCheck: Date) -> UIColor {
        let calendar = Calendar.current
            
        // 1. Filter 'allPosts' to get ONLY the posts for this specific date
        let postsForDay = allPosts.filter { post in
            guard let postDate = post.scheduledAt else { return false }
            return calendar.isDate(postDate, inSameDayAs: dateToCheck)
        }
            
        // 2. If no posts exist on this day, return invisible
        guard !postsForDay.isEmpty else { return .clear }
            
        // 3. Check for specific Statuses
        let hasScheduledPost = postsForDay.contains { post in
            return post.status == .scheduled
        }
        let hasPublishedPost = postsForDay.contains { post in
            return post.status == .published
        }

        
        // Priority 1: If there is ANYTHING scheduled, show Yellow (Work Remaining)
        if hasScheduledPost {
            return .systemYellow
        }
        // Priority 2: If nothing is scheduled, but something is published, show Green (Day Complete)
        else if hasPublishedPost {
            return .systemGreen
        }
        // Fallback
        else {
            return .clear
        }
    }

    //Scroll functionality in calendar.
    func scrollWeek(by days: Int) {
        guard let newStartDate = Calendar.current.date(byAdding: .day, value: days, to: currentWeekStartDate) else { return }
        currentWeekStartDate = newStartDate
        setupCustomCalendar(for: currentWeekStartDate)
    }

    @IBAction func nextTapped(_ sender: Any) {
        scrollWeek(by: 7)
    }
    @IBAction func previousTapped(_ sender: Any) {
        scrollWeek(by: -7)
    }

    //Capsules for saved, scheduled and published posts.
    func applyPillShadowStyle(to stackView: UIStackView) {
        stackView.backgroundColor = .white
        stackView.layer.cornerRadius = 12
        stackView.clipsToBounds = false
        stackView.layer.shadowColor = UIColor.black.cgColor
        stackView.layer.shadowOpacity = 0.1
        stackView.layer.shadowOffset = CGSize(width: 0, height: 1)
        stackView.layer.shadowRadius = 2
    }

    //Functions to navigate to the specific posts screen.
    @objc func savedStackTapped() {
        let storyboard = UIStoryboard(name: "Posts", bundle: nil)
        if let destinationVC = storyboard.instantiateViewController(withIdentifier: "SavedPostsViewControllerID") as? SavedPostsTableViewController {
            self.navigationController?.pushViewController(destinationVC, animated: true)
        } else {
            print("Error: Could not find View Controller with ID 'SavedPostsViewControllerID'")
        }
    }

    @objc func scheduledStackTapped() {
        let storyboard = UIStoryboard(name: "Posts", bundle: nil)
        if let destinationVC = storyboard.instantiateViewController(withIdentifier: "ScheduledPostsViewControllerID") as? ScheduledPostsTableViewController {
            self.navigationController?.pushViewController(destinationVC, animated: true)
        } else {
            print("Error: Could not find View Controller with ID 'SavedPostsViewControllerID'")
        }
    }

    @objc func publishedStackTapped() {
        let storyboard = UIStoryboard(name: "Posts", bundle: nil)
        if let destinationVC = storyboard.instantiateViewController(withIdentifier: "PublishedPostsViewControllerID") as? PublishedPostViewController {
            self.navigationController?.pushViewController(destinationVC, animated: true)
        } else {
            print("Error: Could not find View Controller with ID 'SavedPostsViewControllerID'")
        }
    }
            
    func updateTableViewHeight() {
            postsTableView.layoutIfNeeded()

            let requiredHeight = postsTableView.contentSize.height

            tableViewHeightConstraint.constant = requiredHeight
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
    }
}
extension PostsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(todayScheduledPosts.count)
        return todayScheduledPosts.count
    }
            
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            
        let post = todayScheduledPosts[indexPath.row]
        let hasImages = post.imageNames?.isEmpty == false

        if hasImages {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SchForTodayImageTableViewCell", for: indexPath) as! SchForTodayImageTableViewCell
            cell.configure(with: post)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SchForTodayTableViewCell", for: indexPath) as! SchForTodayTableViewCell
            cell.configure(with: post)
            return cell
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            todayScheduledPosts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //Delete action
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
                    
                    let postToDelete = self.todayScheduledPosts[indexPath.row]
                    
                    if let postId = postToDelete.id {
                        Task {
                            await SupabaseManager.shared.deleteLogPost(id: postId)
                            await MainActor.run {
                                self.todayScheduledPosts.remove(at: indexPath.row)
                                tableView.deleteRows(at: [indexPath], with: .automatic)
                                self.updateTableViewHeight()
                                completionHandler(true)
                            }
                        }
                    }
        }
        deleteAction.image = UIImage(systemName: "trash.fill")

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
                
        return configuration
    }
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "openEditorModal", sender: indexPath)
        }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openEditorModal" {
            var destinationVC: EditorSuiteViewController?
            if let navVC = segue.destination as? UINavigationController {
                destinationVC = navVC.topViewController as? EditorSuiteViewController
            }
            else {
                destinationVC = segue.destination as? EditorSuiteViewController
            }
            if let editorVC = destinationVC, let indexPath = sender as? IndexPath {
                 let selectedPost: Post
                 selectedPost = todayScheduledPosts[indexPath.row]
                let draftData = EditorDraftData(
                                id: selectedPost.id,
                                postHeading: selectedPost.postHeading,
                                platformName: selectedPost.platformName,
                                platformIconName: selectedPost.platformIconName,
                                caption: selectedPost.fullCaption,
                                images: selectedPost.imageNames, // Now passing array directly
                                hashtags: selectedPost.hashtags ?? [],
                                postingTimes: selectedPost.optimalPostingTimes ?? []
                            )
                 
                 editorVC.draft = draftData
            }
        }
    }
}
