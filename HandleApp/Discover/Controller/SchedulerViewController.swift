//
//  SchedulerViewController.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 25/11/25.
//

import UIKit
import Supabase

class SchedulerViewController: UIViewController {
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var previewCaptionLabel: UILabel!
    @IBOutlet weak var previewPlatformLabel: UILabel!
    
    @IBOutlet weak var dateSwitch: UISwitch!
    @IBOutlet weak var dateDetailLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var timeSwitch: UISwitch!
    @IBOutlet weak var timeDetailLabel: UILabel!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    
    var postImage: UIImage?
    var captionText: String?
    var platformText: String?
    var hashtags: [String]?
    var imageNames: [String]?

    override func viewDidLoad() {
        super.viewDidLoad()
      
        setupInitialUI()
        // Do any additional setup after loading the view.
    }
    
    private func setupInitialUI() {

            previewImageView.image = postImage
            previewImageView.layer.cornerRadius = 8

            
            previewCaptionLabel.text = captionText
            previewPlatformLabel.text = platformText
            
            // Configure Pickers initial state
            datePicker.datePickerMode = .date
            timePicker.datePickerMode = .time
            
            dateSwitch.isOn = !datePicker.isHidden
            timeSwitch.isOn = !timePicker.isHidden
        
        }

    @IBAction func dateSwitchToggled(_ sender: UISwitch) {
        if sender.isOn {
            updateDateLabel()
            dateDetailLabel.isHidden = false
        } else {
            dateDetailLabel.isHidden = true
        }

        UIView.animate(withDuration: 0.3) {
            self.datePicker.isHidden = !sender.isOn
            self.datePicker.alpha = sender.isOn ? 1.0 : 0.0
            
            //close time picker if opening date
            if sender.isOn {
                self.timePicker.isHidden = true
                self.timePicker.alpha = 0.0
            }
            self.view.layoutIfNeeded()
        }
        
    }
    
    @IBAction func timeSwitchToggled(_ sender: UISwitch) {
        if sender.isOn {
            updateTimeLabel()
            timeDetailLabel.isHidden = false
        } else {
            timeDetailLabel.isHidden = true
        }

        UIView.animate(withDuration: 0.3) {
            self.timePicker.isHidden = !sender.isOn
            self.timePicker.alpha = sender.isOn ? 1.0 : 0.0
            
            //Close date picker if opening Time
            if sender.isOn {
                self.datePicker.isHidden = true
                self.datePicker.alpha = 0.0
            }
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
            updateDateLabel()
        }
        
        @IBAction func timePickerChanged(_ sender: UIDatePicker) {
            updateTimeLabel()
        }
    
     func updateDateLabel() {
             let formatter = DateFormatter()
             formatter.dateFormat = "E, MMM d, yyyy"
             dateDetailLabel.text = formatter.string(from: datePicker.date)
         }
    
     func updateTimeLabel() {
         let formatter = DateFormatter()
         formatter.timeStyle = .short
         timeDetailLabel.text = formatter.string(from: timePicker.date)
     }
    
    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
            dismiss(animated: true, completion: nil)
        }
    
    @IBAction func scheduleButtonTapped(_ sender: UIBarButtonItem) {
        // 1. Logic to combine Date and Time pickers into one Date object
                let calendar = Calendar.current
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: datePicker.date)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: timePicker.date)
                
                var mergedComps = DateComponents()
                mergedComps.year = dateComponents.year
                mergedComps.month = dateComponents.month
                mergedComps.day = dateComponents.day
                mergedComps.hour = timeComponents.hour
                mergedComps.minute = timeComponents.minute
                
                let finalDate = calendar.date(from: mergedComps) ?? Date()

                // 2. Show Loading
                let alert = UIAlertController(title: nil, message: "Scheduling...", preferredStyle: .alert)
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.style = .medium
                loadingIndicator.startAnimating()
                alert.view.addSubview(loadingIndicator)
                present(alert, animated: true, completion: nil)

                // 3. Create the Post Object
                // We use a dummy UUID for userId; SupabaseManager will overwrite it with the real one.
                let newPost = Post(
                    id: UUID(),
                    userId: UUID(),
                    topicId: nil,
                    status: .scheduled, // Status is SCHEDULED
                    postText: captionText ?? "",
                    fullCaption: captionText ?? "",
                    imageNames: self.imageNames, // The array of filenames passed from Editor
                    platformName: platformText ?? "General",
                    platformIconName: nil,
                    scheduledAt: finalDate, // The calculated date
                    publishedAt: nil,
                    likes: 0,
                    engagementScore: 0,
                    suggestedHashtags: self.hashtags
                )

                // 4. Save to Supabase
                Task {
                    do {
                        try await SupabaseManager.shared.createPost(post: newPost)
                        
                        await MainActor.run {
                            self.dismiss(animated: true) { // Dismiss Loading Alert
                                self.navigateToScheduledTab()
                            }
                        }
                    } catch {
                        await MainActor.run {
                            self.dismiss(animated: true) // Dismiss Loading Alert
                            // Show Error Alert
                            let errAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            errAlert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(errAlert, animated: true)
                        }
                    }
                }
            }
    
    func navigateToScheduledTab() {
            // If your app uses a TabBarController
            if let tabBar = self.tabBarController {
                // Change '1' to the index of your Posts/Schedule tab (0, 1, 2, etc.)
                tabBar.selectedIndex = 1
                self.navigationController?.popToRootViewController(animated: false)
            } else {
                // Fallback if no TabBar
                self.dismiss(animated: true)
            }
        }

}
