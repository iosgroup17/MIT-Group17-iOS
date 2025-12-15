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
    @IBOutlet weak var monthLabel: UILabel!
    
    @IBOutlet weak var publishedStackView: UIStackView!
    @IBOutlet weak var scheduledStackView: UIStackView!
    @IBOutlet weak var savedStackView: UIStackView!
    @IBOutlet weak var postsTableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    var todayScheduledPosts: [Post] = {
        do {
            return try Post.loadTodayScheduledPosts(from: "Posts_data")
        } catch {
            print("FATAL ERROR: Could not load scheduled posts. Details: \(error)")
            return []
        }
    }()
    var allPosts: [Post] = {
        do {
            // We need to load ALL posts to populate the calendar dots,
            // not just "todayScheduledPosts"
            return try Post.loadAllPosts(from: "Posts_data")
        } catch {
            return []
        }
    }()

    var currentWeekStartDate: Date = Calendar.current.startOfDay(for: Date())
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        let calendar = Calendar.current
        currentWeekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        setupCustomCalendar(for: currentWeekStartDate) // Pass the starting date

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
            
        for day in daysOfWeek {
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.textColor = .systemGray
            
            weekDayStackView.addArrangedSubview(label)
        }
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
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
            
        let container = UIView()
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -3)
        ])
        
        // Handle Selection Background
        if isSelected {
            container.backgroundColor = .systemTeal.withAlphaComponent(70/255)
            container.layer.cornerRadius = 18
            container.clipsToBounds = true
            container.heightAnchor.constraint(equalToConstant: 36).isActive = true
        } else {
            container.heightAnchor.constraint(equalToConstant: 36).isActive = true
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
        
        //Check if any post in 'allPosts' has the same day as 'dateToCheck'
        let hasPostOnDate = allPosts.contains { post in
            guard let postDate = post.date else { return false }
            return calendar.isDate(postDate, inSameDayAs: dateToCheck)
        }
        
        //If no post exists, return clear (invisible)
        guard hasPostOnDate else { return .clear }

        //If post exists, check time status
        if dateToCheck < Date() {
            return .systemGreen //Published
        } else {
            return .systemYellow //Scheduled
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
        stackView.layer.cornerRadius = 16
        stackView.clipsToBounds = false
        stackView.layer.shadowColor = UIColor.black.cgColor
        stackView.layer.shadowOpacity = 0.1
        stackView.layer.shadowOffset = CGSize(width: 0, height: 2)
        stackView.layer.shadowRadius = 4 
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
        let cellHeight: CGFloat = 100
        
        let requiredHeight = CGFloat(todayScheduledPosts.count) * cellHeight
        tableViewHeightConstraint.constant = requiredHeight
        view.layoutIfNeeded()
    }
}
extension PostsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(todayScheduledPosts.count)
        return todayScheduledPosts.count
    }
            
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostTableViewCell else {
            fatalError("Could not dequeue PostTableViewCell")
        }
            
        let post = todayScheduledPosts[indexPath.row]
        cell.configure(with: post)
            
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            todayScheduledPosts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        //Edit action        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            self.performSegue(withIdentifier: "openEditorModal", sender: indexPath)
            completionHandler(true)
        }
        editAction.backgroundColor = .systemBlue
        editAction.image = UIImage(systemName: "square.and.pencil")
        
        //Schedule Action
        let scheduleAction = UIContextualAction(style: .normal, title: "Schedule") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return completionHandler(false) }
            self.performSegue(withIdentifier: "openSchedulerModal", sender: indexPath)
            completionHandler(true)
        }
        scheduleAction.backgroundColor = .systemGreen
        scheduleAction.image = UIImage(systemName: "calendar.badge.clock")
        
        //Delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            self.todayScheduledPosts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction, scheduleAction])
        configuration.performsFirstActionWithFullSwipe = false
                
        return configuration
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
                    platformName: selectedPost.platformName,
                    platformIconName: selectedPost.platformIconName,
                    caption: selectedPost.fullCaption ?? "",
                    images: [selectedPost.imageName],
                    hashtags: selectedPost.suggestedHashtags ?? [],
                    postingTimes: selectedPost.optimalPostingTimes ?? []
                )
                 
                 editorVC.draft = draftData
            }
        }
        else if segue.identifier == "openSchedulerModal" {
            if let navVC = segue.destination as? UINavigationController,
                let schedulerVC = navVC.topViewController as? SchedulerViewController {
                    if let indexPath = sender as? IndexPath {
                        let selectedPost: Post
                        selectedPost = todayScheduledPosts[indexPath.row]
                        schedulerVC.postImage = UIImage(named: selectedPost.imageName) 
                        schedulerVC.captionText = selectedPost.text
                        schedulerVC.platformText = selectedPost.platformName
                    }
            }
        }
    }
}

