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
    
    // MARK: - 1. Display Data (The TableView reads these)
    var scheduledTodayPosts: [Post] = {
        do {
            return try Post.loadTodayScheduledPosts(from: "Posts_data")
        } catch {
            print("FATAL ERROR: Could not load scheduled posts. Details: \(error)")
            return []
        }
    }()
    
    var scheduledTomorrowPosts: [Post] = {
        do {
            return try Post.loadTomorrowScheduledPosts(from: "Posts_data")
        } catch {
            print("FATAL ERROR: Could not load scheduled posts. Details: \(error)")
            return []
        }
    }()
    var currentPlatformFilter: String = "All"
    var scheduledLaterPosts: [Post] = {
        do {
            return try Post.loadScheduledPostsAfterDate(from: "Posts_data")
        } catch {
            print("FATAL ERROR: Could not load scheduled posts. Details: \(error)")
            return []
        }
    }()
    
    // MARK: - 2. Backup Data (Used for Filtering)
    // We store the original full lists here so we can restore them when "All" is selected.
    var allTodayPosts: [Post] = []
    var allTomorrowPosts: [Post] = []
    var allLaterPosts: [Post] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = .white
        
        // 3. Save a copy of the data immediately after loading
        allTodayPosts = scheduledTodayPosts
        allTomorrowPosts = scheduledTomorrowPosts
        allLaterPosts = scheduledLaterPosts
    }
    
    // MARK: - PlatformMenuDelegate
    
    func didSelectPlatform(_ platform: String) {
            print("Selected Platform: \(platform)")
                self.currentPlatformFilter = platform // <--- NEW: Save the selected state
                filterScheduledPosts(by: platform)
        }
    
    // MARK: - Filtering Logic
    
    func filterScheduledPosts(by platform: String) {
        print("Filter requested for: [\(platform)]")
        
        if platform == "All" {
            // Restore from backup
            scheduledTodayPosts = allTodayPosts
            scheduledTomorrowPosts = allTomorrowPosts
            scheduledLaterPosts = allLaterPosts
        } else {
            // Filter from backup
            scheduledTodayPosts = allTodayPosts.filter { $0.platformName == platform }
            scheduledTomorrowPosts = allTomorrowPosts.filter { $0.platformName == platform }
            scheduledLaterPosts = allLaterPosts.filter { $0.platformName == platform }
        }
        
        // Refresh the UI
        print("Reloading table with \(scheduledTodayPosts.count + scheduledTomorrowPosts.count + scheduledLaterPosts.count) posts.")
        postTableView.reloadData()
    }
    
    // MARK: - Actions (Popover Menu)
    
    @IBAction func filterButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Filter by Platform", message: nil, preferredStyle: .actionSheet)
                    
                    let platforms = ["All", "LinkedIn", "Instagram", "X"]
                    
                    for platform in platforms {
                        
                        let isSelected = (platform == self.currentPlatformFilter)
                        
                        // Prepend the checkmark symbol if selected
                        let displayTitle = isSelected ? "✓ \(platform)" : platform
                        
                        let action = UIAlertAction(title: displayTitle, style: .default) { [weak self] _ in
                            self?.didSelectPlatform(platform)
                        }
                        
                        alertController.addAction(action)
                    }
                    
                    // Add the Cancel action
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    
                    // 5. iPad Support - ANCHORING FIX
                    // Check if we have a popover controller (i.e., we are on iPad or Mac catalyst)
                    if let popover = alertController.popoverPresentationController {
                        
                        // FIX: Explicitly use the IBOutlet for the bar button item.
                        // This is safer than relying on casting 'sender' for anchoring.
                        popover.barButtonItem = self.filterBarButton
                        
                        // Ensure the table view controller is set as the delegate
                        popover.delegate = self // ScheduledPostsTableViewController must be the delegate
                        
                        popover.permittedArrowDirections = .up
                    }
                    
                    // 6. Present the Alert Controller
                    present(alertController, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Force Popover style on iPhone
        return .none
    }

    // MARK: - Table view data source

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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "scheduled_cell", for: indexPath) as? ScheduledPostsTableViewCell else {
            fatalError("Could not dequeue ScheduledPostsTableViewCell")
        }
        
        if indexPath.section == 0 {
            let post = scheduledTodayPosts[indexPath.row]
            cell.configure(with: post)
            return cell
        } else if indexPath.section == 1 {
            let post = scheduledTomorrowPosts[indexPath.row]
            cell.configure(with: post)
            return cell
        } else {
            let post = scheduledLaterPosts[indexPath.row]
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
    
    // MARK: - Swipe Actions
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
              
        // Edit Action
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
        
        // Schedule Action
        let scheduleAction = UIContextualAction(style: .normal, title: "Schedule") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return completionHandler(false) }
            
          
            self.performSegue(withIdentifier: "openSchedulerModal", sender: indexPath)
            
            completionHandler(true)
        }
        scheduleAction.backgroundColor = .systemGreen
        scheduleAction.image = UIImage(systemName: "calendar.badge.clock")
        
        // Delete Action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            // Remove from the data source to prevent crashes
            if indexPath.section == 0 {
                self.scheduledTodayPosts.remove(at: indexPath.row)
            } else if indexPath.section == 1 {
                self.scheduledTomorrowPosts.remove(at: indexPath.row)
            } else {
                self.scheduledLaterPosts.remove(at: indexPath.row)
            }
            
            // Update table view with animation
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
            
            // 1. Define the destination variable
            var destinationVC: EditorSuiteViewController?
            
            // 2. Check if it's wrapped in a Nav Controller (The Modal Case)
            if let navVC = segue.destination as? UINavigationController {
                destinationVC = navVC.topViewController as? EditorSuiteViewController
            }
            // 3. Or if it's direct (Just in case)
            else {
                destinationVC = segue.destination as? EditorSuiteViewController
            }
            
            // 4. Pass the data
            if let editorVC = destinationVC, let indexPath = sender as? IndexPath {
                 // ... Your existing data passing logic ...
                 let selectedPost: Post
                 if indexPath.section == 0 { selectedPost = scheduledTodayPosts[indexPath.row] }
                 else if indexPath.section == 1 { selectedPost = scheduledTomorrowPosts[indexPath.row] }
                 else { selectedPost = scheduledLaterPosts[indexPath.row] }
                 
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
                
                // 1. Get Destination
                if let navVC = segue.destination as? UINavigationController,
                   let schedulerVC = navVC.topViewController as? SchedulerViewController {
                    
                    // 2. Get Data
                    if let indexPath = sender as? IndexPath {
                        let selectedPost: Post
                        if indexPath.section == 0 { selectedPost = scheduledTodayPosts[indexPath.row] }
                        else if indexPath.section == 1 { selectedPost = scheduledTomorrowPosts[indexPath.row] }
                        else { selectedPost = scheduledLaterPosts[indexPath.row] }
                        
                        // 3. Pass Data (Mapping 'Post' -> 'Scheduler Variables')
                        schedulerVC.postImage = UIImage(named: selectedPost.imageName) // Convert String to UIImage
                        schedulerVC.captionText = selectedPost.text
                        schedulerVC.platformText = selectedPost.platformName
                    }
                }
        }
    }
}
