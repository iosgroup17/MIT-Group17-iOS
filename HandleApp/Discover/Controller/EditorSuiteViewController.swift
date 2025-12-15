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


    @objc func cancelButtonTapped() {
        
            dismiss(animated: true, completion: nil) // close modal
        }

        @objc func doneButtonTapped() {
            
            dismiss(animated: true, completion: nil)
        }
    func setupCollectionViews() {

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
        

    func populateData() {
            guard let data = draft else {
                return
            }
            

            platformNameLabel.text = data.platformName
            platformIconImageView.image = UIImage(named: data.platformIconName)
            captionTextView.text = data.caption
            
        displayedImages.removeAll()
            
            for imageName in data.images {
                if let img = UIImage(named: imageName) {
                    displayedImages.append(img)
                }
            }
           

        imagesCollectionView.reloadData()

            hashtagCollectionView.reloadData()
            timeCollectionView.reloadData()
        }

    func setupNavigationButtons() {
            if self.navigationController?.viewControllers.first == self {


                let cancelImage = UIImage(systemName: "xmark")
                let cancelButton = UIBarButtonItem(image: cancelImage, style: .plain, target: self, action: #selector(cancelButtonTapped))


                let doneImage = UIImage(systemName: "checkmark")
                let doneButton = UIBarButtonItem(image: doneImage, style: .plain, target: self, action: #selector(doneButtonTapped))


                doneButton.tintColor = .systemTeal

                self.navigationItem.leftBarButtonItem = cancelButton
                self.navigationItem.rightBarButtonItem = doneButton
            }
        }
        @objc func cancelButtonTapped() {
        
            dismiss(animated: true, completion: nil) // close modal
        }

        @objc func doneButtonTapped() {
            
            dismiss(animated: true, completion: nil)
        }
    
    // Share action
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



extension EditorSuiteViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

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
                        let image = displayedImages[indexPath.row]
                        cell.configure(with: image)
                    }
                    return cell
            
            
            // Handle Tags & Timings
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
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == imagesCollectionView {

                if indexPath.row == displayedImages.count {
                    print("User tapped Add Button")
                    selectedImageIndex = nil
                    showImagePickerOptions()
                }

                else {
                    print("User tapped Image at index \(indexPath.row) to replace it")
                    selectedImageIndex = indexPath.row
                    showImagePickerOptions()
                }
            }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
 
        if collectionView == imagesCollectionView {
            return CGSize(width: 150, height: 150)
        }
        

        if collectionView == hashtagCollectionView || collectionView == timeCollectionView {
            
            var text = ""
            if collectionView == hashtagCollectionView {
                text = draft?.hashtags[indexPath.row] ?? ""
            } else {
                text = draft?.postingTimes[indexPath.row] ?? ""
            }
            
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
                

                if let firstImageName = draft?.images.first {
                    // Convert the String name to a UIImage
                    destinationVC.postImage = UIImage(named: firstImageName)
                }
                
                // Data passing
                destinationVC.captionText = self.captionTextView.text
                destinationVC.platformText = draft?.platformName ?? "Instagram Post"
            }
        }
    }
    
}


extension EditorSuiteViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func showImagePickerOptions() {

        let alertController = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
                self.openPicker(source: .camera)
            }
            alertController.addAction(cameraAction)
        }
        

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
                self.openPicker(source: .photoLibrary)
            }
            alertController.addAction(libraryAction)
        }
        

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        

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
        picker.allowsEditing = false
        self.present(picker, animated: true, completion: nil)
    }
    
    

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
       
        guard let image = info[.originalImage] as? UIImage else { return }
            

        if let indexToReplace = selectedImageIndex {

            if indexToReplace < displayedImages.count {
                displayedImages[indexToReplace] = image
            }
        } else {

            displayedImages.append(image)
        }

        imagesCollectionView.reloadData()
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
