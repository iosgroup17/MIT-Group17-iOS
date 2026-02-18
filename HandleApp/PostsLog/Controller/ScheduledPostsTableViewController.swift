//
//  ScheduledPostsTableViewController.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 27/11/25.
//

import UIKit

class ScheduledPostsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate{
    
    @IBOutlet weak var postTableView: UITableView!
    @IBOutlet weak var filterBarButton: UIBarButtonItem!
    var scheduledTodayPosts: [Post] = []
    var scheduledTomorrowPosts: [Post] = []
    var scheduledLaterPosts: [Post] = []
    var allFetchedPosts: [Post] = []
    var currentPlatformFilter: String = "All"
    var allTodayPosts: [Post] = []
    var allTomorrowPosts: [Post] = []
    var allLaterPosts: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationManager.shared.requestAuthorization()
        let imageNib = UINib(nibName: "ScheduledPostImageTableViewCell", bundle: nil)
            tableView.register(imageNib, forCellReuseIdentifier: "ScheduledPostImageTableViewCell")
           
        let textNib = UINib(nibName: "ScheduledPostTextTableViewCell", bundle: nil)
            tableView.register(textNib, forCellReuseIdentifier: "ScheduledPostTextTableViewCell")
        
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        allTodayPosts = scheduledTodayPosts
        allTomorrowPosts = scheduledTomorrowPosts
        allLaterPosts = scheduledLaterPosts
        refreshData()
    }
    //Data refresh from supabase.
    func refreshData() {
        Task {
            // 1. Fetch Master List
            let allPosts = await SupabaseManager.shared.fetchUserPosts()
            self.allFetchedPosts = allPosts
            
            // 2. Filter Today
            let today = Date()
            self.scheduledTodayPosts = allPosts.filter { post in
                guard post.status == .scheduled, let date = post.scheduledAt else { return false }
                return Calendar.current.isDate(date, inSameDayAs: today)
            }
            
            // 3. Filter Tomorrow & Later using Extensions
            self.scheduledTomorrowPosts = Post.loadTomorrowScheduledPosts(from: allPosts)
            self.scheduledLaterPosts = Post.loadScheduledPostsLater(from: allPosts)

            await MainActor.run {
                self.postTableView.reloadData()
            }
        }
    }
    
    //Filter by platform.
    func didSelectPlatform(_ platform: String) {
        print("Selected Platform: \(platform)")
        self.currentPlatformFilter = platform
        filterScheduledPosts(by: platform)
    }
    
    func filterScheduledPosts(by platform: String) {
        print("Filter requested for: [\(platform)]")
        if platform == "All" {
            scheduledTodayPosts = allTodayPosts
            scheduledTomorrowPosts = allTomorrowPosts
            scheduledLaterPosts = allLaterPosts
        } else {
            scheduledTodayPosts = allTodayPosts.filter { $0.platformName == platform }
            scheduledTomorrowPosts = allTomorrowPosts.filter { $0.platformName == platform }
            scheduledLaterPosts = allLaterPosts.filter { $0.platformName == platform }
        }
        print("Reloading table with \(scheduledTodayPosts.count + scheduledTomorrowPosts.count + scheduledLaterPosts.count) posts.")
        postTableView.reloadData()
    }
    
    //action on bar button item for platform wise filter. (Menu using UIAlert)
    @IBAction func filterButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Filter by Platform", message: nil, preferredStyle: .actionSheet)
        let platforms = ["All", "LinkedIn", "Instagram", "X"]
        for platform in platforms {
            let isSelected = (platform == self.currentPlatformFilter)
            let displayTitle = isSelected ? "✓ \(platform)" : platform
            let action = UIAlertAction(title: displayTitle, style: .default) { [weak self] _ in
                self?.didSelectPlatform(platform)
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        if let popover = alertController.popoverPresentationController {
            popover.barButtonItem = self.filterBarButton
            popover.delegate = self
            popover.permittedArrowDirections = .up
        }
        present(alertController, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    //Table view
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return scheduledTodayPosts.count
        } else if section == 1 {
            return scheduledTomorrowPosts.count
        } else {
            return scheduledLaterPosts.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 1. Get the post for the current row
        let post: Post
        if indexPath.section == 0 { post = scheduledTodayPosts[indexPath.row] }
        else if indexPath.section == 1 { post = scheduledTomorrowPosts[indexPath.row] }
        else { post = scheduledLaterPosts[indexPath.row] }

        // 2. Check if the post has images to decide which identifier to use
        let hasImages = post.imageNames?.isEmpty == false
        let identifier = hasImages ? "ImageCell" : "TextCell"

        // 3. Dequeue and configure
        if hasImages {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduledPostImageTableViewCell", for: indexPath) as! ScheduledPostImageTableViewCell
            cell.configure(with: post)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduledPostTextTableViewCell", for: indexPath) as! ScheduledPostTextTableViewCell
            cell.configure(with: post)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return scheduledTodayPosts.isEmpty ? nil : "Today"
        } else if section == 1 {
            return scheduledTomorrowPosts.isEmpty ? nil : "Tomorrow"
        } else if section == 2 {
            return scheduledLaterPosts.isEmpty ? nil : "Later"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Delete Action
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            let post: Post
            if indexPath.section == 0 { post = self.scheduledTodayPosts[indexPath.row] }
            else if indexPath.section == 1 { post = self.scheduledTomorrowPosts[indexPath.row] }
            else { post = self.scheduledLaterPosts[indexPath.row] }
            
            guard let postId = post.id else { return completionHandler(false) }
            
            NotificationManager.shared.cancelNotification(for: postId)

            Task {
                await SupabaseManager.shared.deleteLogPost(id: postId)
                
                await MainActor.run {
                    // Remove from local arrays
                    if indexPath.section == 0 { self.scheduledTodayPosts.remove(at: indexPath.row) }
                    else if indexPath.section == 1 { self.scheduledTomorrowPosts.remove(at: indexPath.row) }
                    else { self.scheduledLaterPosts.remove(at: indexPath.row) }
                    
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    completionHandler(true)
                }
            }
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        
        return configuration
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "openEditorModal", sender: indexPath)
        }
    //Pass data to scheduler and editor suite VC
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
                 if indexPath.section == 0 { selectedPost = scheduledTodayPosts[indexPath.row] }
                 else if indexPath.section == 1 { selectedPost = scheduledTomorrowPosts[indexPath.row] }
                 else { selectedPost = scheduledLaterPosts[indexPath.row] }
                let draftData = EditorDraftData(
                                id: selectedPost.id,
                                postHeading: selectedPost.postHeading,
                                platformName: selectedPost.platformName,
                                platformIconName: selectedPost.platformIconName,
                                caption: selectedPost.fullCaption,
                                images: selectedPost.imageNames,
                                hashtags: selectedPost.suggestedHashtags ?? [],
                                postingTimes: selectedPost.optimalPostingTimes ?? []
                            )
                 editorVC.draft = draftData
            }
        }
    }
}
