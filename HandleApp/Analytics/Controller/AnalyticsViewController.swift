//
//  AnalyticsViewController.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 25/11/25.
//

import UIKit

class AnalyticsViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // Bring back the Navigation Bar so we can see the Link Button!
            // 
            navigationController?.setNavigationBarHidden(false, animated: true)
            
            // Removing the text "Back" from the invisible back button so it doesn't mess up layout
            navigationItem.backButtonTitle = ""

        }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupDesign()
        setupData()
            
        // Hides the back button on screen so user can't go back to OAuth
        self.navigationItem.hidesBackButton = true
        
        let linkButton = UIBarButtonItem(image: UIImage(systemName: "link"), style: .plain, target: self, action: #selector(didTapManageConnections))
        self.navigationItem.rightBarButtonItem = linkButton
    }
    

    @objc func didTapManageConnections() {
        // Show Auth Screen again for completion, as a (Modal), not a push nav
        // This should allow users to manage their connections without losing their current analytics view programatiically specify modal presentation style


        let storyboard = UIStoryboard(name: "Analytics", bundle: nil)
        if let authVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController {
            
            // slide up from bottom full screen modal presentation
            authVC.modalPresentationStyle = .pageSheet
            
            // Present it
            self.present(authVC, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func didTapHandleScoreInfo(_ sender: Any) {
        // Creates the popup
            let alert = UIAlertController(
                title: "What is Handle Score?",
                message: "Your Handle Score is calculated based on your posting consistency and growth.\n\nA score above 5% indicates healthy growth!\n\nIt’s calculated using the formula: Handle Rate (%) = ((Likes + 2 × Comments + 3 × Reposts) ÷ Impressions) × 100\n\nEach interaction type carries different weight to reflect its impact:\nLikes → quick appreciation\nComments → deeper engagement\nReposts/Shares → strong advocacy and content reach",
                preferredStyle: .alert
            )
            
            // Adds an "OK" button
            alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: nil))
            
            // Shows it
            self.present(alert, animated: true, completion: nil)
    }
    
    
    
    @IBAction func didTapDismissSuggestion(_ sender: UIButton) {
        guard let cardView = sender.superview else { return }
                
                // Animate it away
                UIView.animate(withDuration: 0.3) {
                    cardView.isHidden = true
                    cardView.alpha = 0
                }
                
                // Show Red Toast msg
                showToast(message: "Suggestion Removed", isSuccess: false)
        
    }
    
    @IBAction func didTapApplySuggestion(_ sender: UITapGestureRecognizer) {
        guard let cardView = sender.view else { return }
                
                // Animate it away
                UIView.animate(withDuration: 0.3) {
                    cardView.isHidden = true
                    cardView.alpha = 0
                }
                
                // 3. Show Green Toast
                showToast(message: "Applying Suggestion...", isSuccess: true)
    }
    
    // MARK: - Setup Functions
    func setupDesign() {
        // apply tint color - system teal globally for this view
        self.view.tintColor = UIColor.systemTeal
    }

    func setupData() {
        // This is a placeholder for where we will fetch API data later
        print("Data setup complete")
    }
    

    
    // MARK: - Toast Logic for smart suggestions

    func showToast(message: String, isSuccess: Bool) {

        // Create the container for toast
        let toastView = UIView()
        toastView.backgroundColor = isSuccess ? UIColor.systemGreen : UIColor.systemRed
        toastView.alpha = 0.0
        toastView.layer.cornerRadius = 20
        toastView.clipsToBounds = true
        
        // Create the label
        let label = UILabel()
        label.text = (isSuccess ? "✓ " : "✕ ") + message
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        
        // Add to screen
        toastView.addSubview(label)
        self.view.addSubview(toastView) // Add to main view window
        
        // Layout
        // Centered at top, width 200, height 40
        let screenWidth = self.view.frame.width
        // this centers the toast at the top of the screen in it's x position

        toastView.frame = CGRect(x: (screenWidth - 200)/2, y: 60, width: 200, height: 40)
        label.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        // this toastView.frame positions it 60 points from the top of the screen and centers it horizontally.
        // label.frame makes the label fill the entire toast view. This way the text is centered within the toast background.

        // Animate In & Out
        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1.0
            toastView.frame.origin.y = 100 // Slide down slightly
        }) { _ in
            // Wait 2 seconds, then fade out
            UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
                toastView.alpha = 0.0
                toastView.frame.origin.y = 60 // Slide back up
            }) { _ in
                toastView.removeFromSuperview()
            }
        }
    }
    
    

    
}
