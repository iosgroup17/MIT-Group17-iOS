//
//  SchedulerViewController.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 25/11/25.
//

import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInitialUI()
        // Do any additional setup after loading the view.
    }
    
    private func setupInitialUI() {
            // Populate preview data
            previewImageView.image = postImage
            // Optional: Make image corners rounded like the design
            previewImageView.layer.cornerRadius = 8
            previewImageView.clipsToBounds = true
            
            previewCaptionLabel.text = captionText
            previewPlatformLabel.text = platformText
            
            // Configure Pickers initial state
            // Ensure Date picker is set to Inline style in storyboard for calendar view
            datePicker.datePickerMode = .date
            // Ensure Time picker is set to Time mode in storyboard
            timePicker.datePickerMode = .time
            
            // Ensure switches match the hidden state of pickers initially
            dateSwitch.isOn = !datePicker.isHidden
            timeSwitch.isOn = !timePicker.isHidden
        
        }

    @IBAction func dateSwitchToggled(_ sender: UISwitch) {
        view.endEditing(true)
                
                // Update the Blue Label immediately when switch turns on
                if sender.isOn {
                    updateDateLabel()
                    dateDetailLabel.isHidden = false
                } else {
                    dateDetailLabel.isHidden = true
                }

                UIView.animate(withDuration: 0.3) {
                    self.datePicker.isHidden = !sender.isOn
                    self.datePicker.alpha = sender.isOn ? 1.0 : 0.0
                    
                    // Accordion: Close Time picker if opening Date
                    if sender.isOn {
                        self.timePicker.isHidden = true
                        self.timePicker.alpha = 0.0
                    }
                    self.view.layoutIfNeeded()
                }
    }
    
    @IBAction func timeSwitchToggled(_ sender: UISwitch) {
        view.endEditing(true)
                
                // Update the Blue Label immediately when switch turns on
                if sender.isOn {
                    updateTimeLabel()
                    timeDetailLabel.isHidden = false
                } else {
                    timeDetailLabel.isHidden = true
                }

                UIView.animate(withDuration: 0.3) {
                    self.timePicker.isHidden = !sender.isOn
                    self.timePicker.alpha = sender.isOn ? 1.0 : 0.0
                    
                    // Accordion: Close Date picker if opening Time
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
            // Normal Date: "Mon, Dec 9, 2025"
            formatter.dateFormat = "E, MMM d, yyyy"
            dateDetailLabel.text = formatter.string(from: datePicker.date)
        }
    
    func updateTimeLabel() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short // "8:00 PM"
        timeDetailLabel.text = formatter.string(from: timePicker.date)
    }
    
    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
            dismiss(animated: true, completion: nil)
        }
    
    @IBAction func scheduleButtonTapped(_ sender: UIBarButtonItem) {
            // Here you would combine the date and time and save the schedule
            
            let selectedDate = dateSwitch.isOn ? datePicker.date : nil
            let selectedTime = timeSwitch.isOn ? timePicker.date : nil
            
            print("Scheduling Post...")
            if let date = selectedDate {
                 print("Date selected: \(date)")
            }
            if let time = selectedTime {
                 print("Time selected: \(time)")
            }
            
            // TODO: Add your actual saving logic here (e.g., save to CoreData, Firebase, etc.)
        dismiss(animated: true, completion: nil)
        }

}
