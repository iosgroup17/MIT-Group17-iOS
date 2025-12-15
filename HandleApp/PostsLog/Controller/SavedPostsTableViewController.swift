//
//  SavedPostsTableViewController.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 26/11/25.
//

import UIKit

class SavedPostsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    
    @IBOutlet weak var postTableView: UITableView!
    @IBOutlet weak var filterBarButton: UIBarButtonItem!
    var savedPosts: [Post] = {
        do {
            return try Post.loadSavedPosts(from: "Posts_data")
        } catch {
            print("FATAL ERROR: Could not load saved posts. Details: \(error)")
            return []
        }
    }()
    var displayedPosts: [Post] = []
    var currentPlatformFilter: String = "All"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayedPosts = savedPosts
    }
    
    //Filter by platform.
    func didSelectPlatform(_ platform: String) {
        print("Selected Platform: \(platform)")
            self.currentPlatformFilter = platform 
            filterSavedPosts(by: platform)
    }

    func filterSavedPosts(by platform: String) {
        print("Filter requested for: [\(platform)]") 
        if platform == "All" {
            displayedPosts = savedPosts
        } else {
            displayedPosts = savedPosts.filter { post in
                print("Post platformName: [\(post.platformName)] vs Target: [\(platform)]")
                return post.platformName == platform
            }
        }
        print("Posts displayed after filter: \(displayedPosts.count)")
        postTableView.reloadData( )
    }

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
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedPosts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "saved_cell", for: indexPath) as? SavedPostsTableViewCell else {
            fatalError("Could not dequeue SavedPostsTableViewCell")
        }    
        let post = displayedPosts[indexPath.row]
        cell.configure(with: post)
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            savedPosts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

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
        
        // Schedule Action
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
            self.displayedPosts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction, scheduleAction])
        configuration.performsFirstActionWithFullSwipe = false
                
        return configuration
    }
    
    //Pass data to scheduler and Editor suite VC.
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
                selectedPost = displayedPosts[indexPath.row]
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
                        selectedPost = displayedPosts[indexPath.row]
                        schedulerVC.postImage = UIImage(named: selectedPost.imageName) 
                        schedulerVC.captionText = selectedPost.text
                        schedulerVC.platformText = selectedPost.platformName
                    }
            }
        }
    }
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
