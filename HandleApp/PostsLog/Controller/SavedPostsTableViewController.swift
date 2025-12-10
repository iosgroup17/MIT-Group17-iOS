//
//  SavedPostsTableViewController.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 26/11/25.
//

import UIKit

class SavedPostsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, PlatformMenuDelegate {
    func didSelectPlatform(_ platform: String) {
        print("Selected Platform: \(platform)")
    filterSavedPosts(by: platform)
    }
    
    @IBOutlet weak var postTableView: UITableView!
    var savedPosts: [Post] = {
        do {
            return try Post.loadSavedPosts(from: "Posts_data")
        } catch {
            print("FATAL ERROR: Could not load saved posts. Details: \(error)")
            return []
        }
    }()
    var displayedPosts: [Post] = []
    func filterSavedPosts(by platform: String) {
        print("Filter requested for: [\(platform)]") // Check the input string

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
    @IBOutlet weak var filterBarButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        displayedPosts = savedPosts
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    @IBAction func filterButtonTapped(_ sender: Any) {
        guard let menuVC = storyboard?.instantiateViewController(withIdentifier: "PlatformMenuID") as? PlatformFilterViewController else {
                    return
                }
        menuVC.delegate = self
                // 2. Set the Presentation Style to Popover
                menuVC.modalPresentationStyle = .popover
                
                // 3. Configure the Popover Presentation Controller
                guard let popoverPC = menuVC.popoverPresentationController else { return }
                
                // Set the anchor point: This tells the popover where to appear from.
        popoverPC.barButtonItem = sender as? UIBarButtonItem // Anchor it to the UIBarButtonItem
                
                // Set the delegate for custom behavior (optional, but good practice)
                popoverPC.delegate = self
                
                // Customize the arrow direction (optional, but standard for menus)
                popoverPC.permittedArrowDirections = .up
                
                // 4. Present the view controller
                present(menuVC, animated: true, completion: nil)
    }
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
            // Force the Popover style instead of defaulting to full screen on iPhone
            return .none
        }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
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

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            savedPosts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
                
                // 1. Define the Edit Action
                let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completionHandler) in
                    guard let self = self else {
                        completionHandler(false)
                        return
                    }
                    
                    
                    
                    // Signal that the action was handled successfully
                    completionHandler(true)
                }
                
                editAction.backgroundColor = .systemBlue // Non-destructive color
                editAction.image = UIImage(systemName: "square.and.pencil")
        let scheduleAction = UIContextualAction(style: .normal, title: "Schedule") { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
           
            
            // Signal that the action was handled successfully
            completionHandler(true)
            
        }
        
        scheduleAction.backgroundColor = .systemGreen
        scheduleAction.image = UIImage(systemName: "calendar.badge.clock")
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
                    guard let self = self else {
                        completionHandler(false)
                        return
                    }
                    
                    // Update data model
                    self.savedPosts.remove(at: indexPath.row)
                    
                    // Update table view with animation
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    
                    completionHandler(true)
                }
                deleteAction.image = UIImage(systemName: "trash.fill")
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction, scheduleAction])
                
                // Set to false so that a full swipe only reveals the actions, instead of triggering Delete immediately.
                configuration.performsFirstActionWithFullSwipe = false
                
                return configuration
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
