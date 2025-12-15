//
//  EditorSuiteViewController.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 25/11/25.
//

import UIKit
import PhotosUI

class EditorSuiteViewController: UIViewController {
    
    @IBOutlet weak var platformIconImageView: UIImageView!
    @IBOutlet weak var platformNameLabel: UILabel!
    
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    
    @IBOutlet weak var captionTextView: UITextView!
    
    @IBOutlet weak var regenerateButton: UIButton!
    
    @IBOutlet weak var hashtagContainerView: UIView!
    @IBOutlet weak var hashtagTitleLabel: UILabel!
    @IBOutlet weak var hashtagCollectionView: UICollectionView!
    
    @IBOutlet weak var timeContainerView: UIView!
    @IBOutlet weak var timeTitleLabel: UILabel!
    @IBOutlet weak var timeCollectionView: UICollectionView!
    
    var draft: EditorDraftData?
    
    var displayedImages: [UIImage] = []
    
    var selectedImageIndex: Int? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViews()
        setupUI()
        populateData()
        setupNavigationButtons()
        
    }
            func setupNavigationButtons() {
                    if self.navigationController?.viewControllers.first == self {
                        
                        // Define your custom Teal color once

                        // 1. Create Cancel button (X)
                        // This button will inherit the default navigation bar tint color (e.g., system blue).
                        let cancelImage = UIImage(systemName: "xmark")
                        let cancelButton = UIBarButtonItem(image: cancelImage, style: .plain, target: self, action: #selector(cancelButtonTapped))

                        // 2. Create Done button (✓) using the *unfilled* checkmark
                        let doneImage = UIImage(systemName: "checkmark")
                        let doneButton = UIBarButtonItem(image: doneImage, style: .plain, target: self, action: #selector(doneButtonTapped))

                        // 3. APPLY TEAL COLOR *ONLY* TO THE DONE BUTTON
                        // Setting the tintColor directly on the UIBarButtonItem only affects that item.
                        doneButton.tintColor = .systemTeal

                        self.navigationItem.leftBarButtonItem = cancelButton
                        self.navigationItem.rightBarButtonItem = doneButton
                    }
                }


    @objc func cancelButtonTapped() {
            // Just close the modal
            dismiss(animated: true, completion: nil)
        }

        @objc func doneButtonTapped() {
            
            dismiss(animated: true, completion: nil)
        }
    func setupCollectionViews() {
            // 1. Assign the Boss (Data Source & Delegate)
            imagesCollectionView.dataSource = self
            imagesCollectionView.delegate = self
            
            hashtagCollectionView.dataSource = self
            hashtagCollectionView.delegate = self
            
            timeCollectionView.dataSource = self
            timeCollectionView.delegate = self
            
            
            imagesCollectionView.register(UINib(nibName: "ImageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ImageCollectionViewCell")
        
            let hashtagNib = UINib(nibName: "HashtagCollectionViewCell", bundle: nil)
            hashtagCollectionView.register(hashtagNib, forCellWithReuseIdentifier: "HashtagCollectionViewCell")
            timeCollectionView.register(hashtagNib, forCellWithReuseIdentifier: "HashtagCollectionViewCell")
        }
    
    func setupUI() {
            
            captionTextView.layer.cornerRadius = 8
            captionTextView.layer.borderWidth = 1
            captionTextView.layer.borderColor = UIColor.systemGray5.cgColor
            captionTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
           
            hashtagContainerView.layer.cornerRadius = 12
            hashtagContainerView.layer.borderWidth = 1
            hashtagContainerView.layer.borderColor = UIColor.systemGray4.cgColor
            
            timeContainerView.layer.cornerRadius = 12
            timeContainerView.layer.borderWidth = 1
            timeContainerView.layer.borderColor = UIColor.systemGray4.cgColor
    
        }
        
    // Populate Data (Fill in the blanks)
    func populateData() {
            guard let data = draft else {
                return
            }
            
            // 1. Set Header
            platformNameLabel.text = data.platformName
            platformIconImageView.image = UIImage(named: data.platformIconName)
            captionTextView.text = data.caption
            
        displayedImages.removeAll() // clear old data
            
            for imageName in data.images {
                if let img = UIImage(named: imageName) {
                    displayedImages.append(img)
                }
            }
           

        imagesCollectionView.reloadData()
            // 3. Reload Hashtags/Time (Keep as Collection Views)
            hashtagCollectionView.reloadData()
            timeCollectionView.reloadData()
        }
    
    // MARK: - Share Sheet / Publish Action
    @IBAction func publishButtonTapped(_ sender: UIButton) {
        
        var itemsToShare: [Any] = []
        
        if let text = captionTextView.text, !text.isEmpty {
            itemsToShare.append(text)
        }
        
        itemsToShare.append(contentsOf: displayedImages)
        
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        self.present(activityViewController, animated: true, completion: nil)
    }

}


//Collection View Data Source
extension EditorSuiteViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Simple Switch to decide count
        switch collectionView {
        case imagesCollectionView:
                    return displayedImages.count + 1
        case hashtagCollectionView: return draft?.hashtags.count ?? 0
        case timeCollectionView:    return draft?.postingTimes.count ?? 0
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
            
        case imagesCollectionView:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as! ImageCollectionViewCell
                
            if indexPath.row == displayedImages.count {
                        cell.configureAsAddButton()
                    } else {
                        // It's a real image, grab it from our array
                        let image = displayedImages[indexPath.row]
                        cell.configure(with: image)
                    }
                    return cell
            
            
            // 2. Handle Tags & Times (They share the same cell type!)
        case hashtagCollectionView, timeCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HashtagCollectionViewCell", for: indexPath) as! HashtagCollectionViewCell
            
            if collectionView == hashtagCollectionView {
                if let tag = draft?.hashtags[indexPath.row] {
                    cell.configure(text: tag)
                }
            } else {
                if let time = draft?.postingTimes[indexPath.row] {
                    cell.configure(text: time)
                }
            }
            return cell
            
        default: return UICollectionViewCell()
        }
    }
    
    // MARK: - Handle Taps (Logic for Add vs Replace)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == imagesCollectionView {

                if indexPath.row == displayedImages.count {
                    print("User tapped Add Button")
                    selectedImageIndex = nil // Set to NIL so the picker knows to ADD a new one
                    showImagePickerOptions()
                }
                // User clicked an existing image
                else {
                    print("User tapped Image at index \(indexPath.row) to replace it")
                    selectedImageIndex = indexPath.row // SAVE the specific index (e.g., 0, 1)
                    showImagePickerOptions()
                }
            }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 1. Images: Make them nice rectangular posters
        if collectionView == imagesCollectionView {
            return CGSize(width: 150, height: 150)
        }
        
        // 2. Hashtags & Times: Make them pills that fit the text
        if collectionView == hashtagCollectionView || collectionView == timeCollectionView {
            
            var text = ""
            if collectionView == hashtagCollectionView {
                text = draft?.hashtags[indexPath.row] ?? ""
            } else {
                text = draft?.postingTimes[indexPath.row] ?? ""
            }
            
            // Calculate width based on text length + padding
            let font = UIFont.systemFont(ofSize: 13, weight: .medium)
            let width = text.size(withAttributes: [.font: font]).width + 30
            
            return CGSize(width: width, height: 32)
        }
        
        return CGSize(width: 50, height: 50)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSchedulerSegue" {
            
            if let navVC = segue.destination as? UINavigationController,
               let destinationVC = navVC.topViewController as? SchedulerViewController {
                
                // 1. Get the first image name from your draft data
                if let firstImageName = draft?.images.first {
                    // Convert the String name to a UIImage
                    destinationVC.postImage = UIImage(named: firstImageName)
                }
                
                // 2. Pass the rest of the data
                destinationVC.captionText = self.captionTextView.text
                destinationVC.platformText = draft?.platformName ?? "Instagram Post"
            }
        }
    }
    
}

// Image Picker & Navigation
extension EditorSuiteViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func showImagePickerOptions() {
        // Create the Action Sheet
        let alertController = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        
        // 1. Camera Option
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
                self.openPicker(source: .camera)
            }
            alertController.addAction(cameraAction)
        }
        
        // 2. Library Option
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
                self.openPicker(source: .photoLibrary)
            }
            alertController.addAction(libraryAction)
        }
        
        // 3. Cancel Option
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // iPad Support (prevents crash on iPad)
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func openPicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = source
        picker.allowsEditing = false // Set to true if you want square crop
        self.present(picker, animated: true, completion: nil)
    }
    
    
    // This function runs when the user picks a photo
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
       
        guard let image = info[.originalImage] as? UIImage else { return }
            
            // 2. CHECK THE TRACKER VARIABLE
        if let indexToReplace = selectedImageIndex {
                // CASE A: We have a specific index stored, so REPLACE that exact image.
            if indexToReplace < displayedImages.count { // Safety check
                displayedImages[indexToReplace] = image
            }
        } else {
            // CASE B: The variable is nil, so ADD a new image to the end.
            displayedImages.append(image)
        }
        
        // 2. Refresh the UI to show the new photo
        imagesCollectionView.reloadData()
        
        // 3. Close the picker
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
