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
            
            let selectedDate = dateSwitch.isOn ? datePicker.date : nil
            let selectedTime = timeSwitch.isOn ? timePicker.date : nil
            
            print("Scheduling Post...")
            if let date = selectedDate {
                 print("Date selected: \(date)")
            }
            if let time = selectedTime {
                 print("Time selected: \(time)")
            }

        dismiss(animated: true, completion: nil)
        }

}
