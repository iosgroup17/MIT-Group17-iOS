//
//  SchedulerViewController.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 25/11/25.
//

import UIKit
import Supabase

struct ScheduledPostData {
    let platformName: String
    let iconName: String?
    let caption: String
    let images: [UIImage]?
    let hashtags: [String]
}

class SchedulerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    @IBOutlet weak var postPreviewCollectionView: UICollectionView!
    
    @IBOutlet weak var dateSwitch: UISwitch!
    @IBOutlet weak var dateDetailLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var timeSwitch: UISwitch!
    @IBOutlet weak var timeDetailLabel: UILabel!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    var postData: ScheduledPostData?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupInitialUI()
        // Do any additional setup after loading the view.
    }
    
    private func setupCollectionView() {
        postPreviewCollectionView.delegate = self
        postPreviewCollectionView.dataSource = self
        
        // Register BOTH XIBs
        postPreviewCollectionView.register(
            UINib(nibName: "PostPreviewImageCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "PostPreviewImageCollectionViewCell"
        )
        
        postPreviewCollectionView.register(
            UINib(nibName: "PostPreviewTextCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "PostPreviewTextCollectionViewCell"
        )
        
        postPreviewCollectionView.isScrollEnabled = false
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            // ITEM: Takes up 100% of the Group
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // GROUP: Fixed Height (300), Width fills the Section
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(145)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            // SECTION: Apply the padding here
            let section = NSCollectionLayoutSection(group: group)
            
            // This creates the "Screen Width - 48" effect
            // (24 padding on Left + 24 padding on Right)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12)
            
            return section
        }
                
        postPreviewCollectionView.collectionViewLayout = layout
    }
    
    private func setupInitialUI() {
        // Configure Pickers initial state
        datePicker.datePickerMode = .date
        timePicker.datePickerMode = .time
        
        dateSwitch.isOn = !datePicker.isHidden
        timeSwitch.isOn = !timePicker.isHidden
        
        // Update labels immediately
        updateDateLabel()
        updateTimeLabel()
        
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
        // 1. Combine Date/Time
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
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 20, width: 50, height: 50))
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.style = .medium
                loadingIndicator.startAnimating()
                alert.view.addSubview(loadingIndicator)
                present(alert, animated: true, completion: nil)

                // 3. Create Post Object (Using postData!)
                let newPost = Post(
                    id: UUID(),
                    userId: UUID(), // SupabaseManager will handle this
                    topicId: nil,
                    status: .scheduled,
                    postText: postData?.caption ?? "",
                    fullCaption: postData?.caption ?? "",
                    imageNames: [], // TODO: You need to upload `postData?.images` and put URLs/Names here
                    platformName: postData?.platformName ?? "General",
                    platformIconName: postData?.iconName,
                    scheduledAt: finalDate,
                    publishedAt: nil,
                    likes: 0,
                    engagementScore: 0,
                    suggestedHashtags: postData?.hashtags
                )

                // 4. Save to Supabase
                Task {
                    do {
                        try await SupabaseManager.shared.createPost(post: newPost)
                        
                        await MainActor.run {
                            self.dismiss(animated: true) {
                                self.navigateToScheduledTab()
                            }
                        }
                    } catch {
                        await MainActor.run {
                            self.dismiss(animated: true)
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return postData == nil ? 0 : 1
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let data = postData else { return UICollectionViewCell() }
            
            if let images = data.images, let firstImage = images.first {
                let cell = postPreviewCollectionView.dequeueReusableCell(withReuseIdentifier: "PostPreviewImageCollectionViewCell", for: indexPath) as! PostPreviewImageCollectionViewCell
                cell.configure(
                    platformName: data.platformName,
                    iconName: data.iconName,
                    caption: data.caption,
                    image: firstImage
                )
                return cell
            } else {
                let cell = postPreviewCollectionView.dequeueReusableCell(withReuseIdentifier: "PostPreviewTextCollectionViewCell", for: indexPath) as! PostPreviewTextCollectionViewCell
                cell.configure(
                    platformName: data.platformName,
                    iconName: data.iconName,
                    caption: data.caption
                )
                return cell
            }
        }

}
