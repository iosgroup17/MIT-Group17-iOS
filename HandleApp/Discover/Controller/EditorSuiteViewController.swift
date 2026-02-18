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
    
    private let captionService: CaptionGenerator = RegenerateCaption()
    
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
            platformIconImageView.image = UIImage(named: data.platformIconName ?? "")
            captionTextView.text = data.caption
            
        displayedImages.removeAll()
            
            for imageName in data.images ?? []{
                if let img = UIImage(named: imageName) {
                    displayedImages.append(img)
                }
            }
           

        imagesCollectionView.reloadData()

            hashtagCollectionView.reloadData()
            timeCollectionView.reloadData()
        }
    
    
    

    func setupNavigationButtons() {
        let shareAction = UIAction(image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            self?.handleShareFlow()
        }
        let shareButton = UIBarButtonItem(primaryAction: shareAction)
        self.navigationItem.rightBarButtonItem = shareButton
    }
    
    
    @IBAction func regenerateTapped(_ sender: UIButton) {
        guard let currentText = captionTextView.text else { return }

                sender.isEnabled = false
                
        Task {
            do {
                let newCaption = try await captionService.regenerate(currentText, tone: "professional")

                await MainActor.run {
                    self.captionTextView.text = newCaption
                    sender.isEnabled = true
                }
            } catch {
                print("oops: \(error)")
                await MainActor.run { sender.isEnabled = true }
            }
        }
        
    }
    

    @IBAction func saveButtonTapped(_ sender: Any) {

                let loadingAlert = UIAlertController(title: "Saving...", message: nil, preferredStyle: .alert)
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 20, width: 50, height: 50))
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.style = .medium
                loadingIndicator.startAnimating()
                loadingAlert.view.addSubview(loadingIndicator)
                
                present(loadingAlert, animated: true)
                
        let savedPost = Post(
                id: draft?.id ?? UUID(),
                userId: SupabaseManager.shared.currentUserID,
                topicId: nil,

                status: .saved,

                postHeading: draft?.postHeading ?? "",
                fullCaption: draft?.caption,

                imageNames: draft?.images,
                
                platformName: draft?.platformName ?? "General",
                platformIconName: draft?.platformIconName,

                hashtags: draft?.hashtags,

                scheduledAt: nil,
                publishedAt: nil,

                likes: 0,
                engagementScore: 0.0,
                suggestedHashtags: nil,
                optimalPostingTimes: nil
            )
        
        print(SupabaseManager.shared.currentUserID)
       
                        Task {
                            do {
                                try await SupabaseManager.shared.upsertPost(post: savedPost)
                
                                await MainActor.run {
                                    loadingAlert.dismiss(animated: true) {
                                        self.dismiss(animated: true) {
                                            print("Post saved successfully.")
                                        }
                                    }
                                }
                            } catch {

                                await MainActor.run {
                                    NotificationManager.shared.scheduleDraftReminder(for: savedPost)
                                    loadingAlert.dismiss(animated: true) {
                                        let errAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                                        print(error.localizedDescription)
                                        errAlert.addAction(UIAlertAction(title: "OK", style: .default))
                                        self.present(errAlert, animated: true)
                                    }
                                }
                            }
                        }
    }
    
    
    func getFileURLs(from images: [UIImage]) -> [URL] {
        var urls: [URL] = []
        for (index, image) in images.enumerated() {
            if let data = image.jpegData(compressionQuality: 0.9) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("share_image_\(index).jpg")
                try? data.write(to: tempURL)
                urls.append(tempURL)
            }
        }
        return urls
    }
    func markPostAsPublished() {
        guard let draftID = draft?.id else { return }

        let publishedPost = Post(
            id: draftID,
            userId: SupabaseManager.shared.currentUserID,
            topicId: nil,
            status: .published,
            postHeading: draft?.postHeading ?? "",
            fullCaption: draft?.caption,
            imageNames: draft?.images,
            platformName: draft?.platformName ?? "General",
            platformIconName: draft?.platformIconName,
            hashtags: draft?.hashtags,
            scheduledAt: nil,
            publishedAt: Date(),
            likes: 0,
            engagementScore: 0.0,
            suggestedHashtags: nil,
            optimalPostingTimes: nil
        )
        
        Task {
            do {
                try await SupabaseManager.shared.upsertPost(post: publishedPost)
                await MainActor.run {
                    NotificationManager.shared.cancelNotification(for: draftID)
                    self.showToast(message: "Post marked as Published!")

                    self.navigationController?.popToRootViewController(animated: true)
                }
            } catch {
                print("Failed to update status: \(error)")
            }
        }
    }
    
    func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14, weight: .medium)
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 15
        toastLabel.clipsToBounds = true
        
        let expectedSize = toastLabel.sizeThatFits(CGSize(width: self.view.frame.width - 40, height: 40))
        toastLabel.frame = CGRect(x: self.view.frame.width/2 - (expectedSize.width + 20)/2,
                                  y: self.view.frame.height - 100,
                                  width: expectedSize.width + 20,
                                  height: 35)
        
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 0.3, animations: { toastLabel.alpha = 1.0 }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut, animations: { toastLabel.alpha = 0.0 }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
    
    func handleShareFlow() {
        guard let text = captionTextView.text else { return }
        
        UIPasteboard.general.string = text
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let textSource = ShareTextSource(text: text)
        let imageURLs = getFileURLs(from: displayedImages)
        
        var itemsToShare: [Any] = [textSource]
        itemsToShare.append(contentsOf: imageURLs)
        
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in

            imageURLs.forEach { try? FileManager.default.removeItem(at: $0) }
    
            if completed {

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let alert = UIAlertController(
                        title: "Confirm Post",
                        message: "Did you successfully share this post to \(self.draft?.platformName ?? "the platform")?",
                        preferredStyle: .alert
                    )
                    
                    let yesAction = UIAlertAction(title: "Yes, it's posted!", style: .default) { _ in
                        self.markPostAsPublished()
                    }
                    
                    let noAction = UIAlertAction(title: "Not yet", style: .cancel, handler: nil)
                    
                    alert.addAction(yesAction)
                    alert.addAction(noAction)
                    
                    self.present(alert, animated: true)
                }
            }
        }
        
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = self.navigationItem.rightBarButtonItem
        }
        
        self.present(activityVC, animated: true)
    }

}



extension EditorSuiteViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        switch collectionView {
        case imagesCollectionView:
                    return displayedImages.count + 1
        case hashtagCollectionView: return draft?.hashtags?.count ?? 0
        case timeCollectionView:    return draft?.postingTimes?.count ?? 0
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
            
    
        case hashtagCollectionView, timeCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HashtagCollectionViewCell", for: indexPath) as! HashtagCollectionViewCell
            
            if collectionView == hashtagCollectionView {
                if let tag = draft?.hashtags?[indexPath.row] {
                    cell.configure(text: tag)
                }
            } else {
                if let time = draft?.postingTimes?[indexPath.row] {
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
                text = draft?.hashtags?[indexPath.row] ?? ""
            } else {
                text = draft?.postingTimes?[indexPath.row] ?? ""
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
                    
                    // 1. Gather Data (Keep your existing logic)
                    let finalCaption = self.captionTextView.text ?? ""
                    let finalImages = self.displayedImages.isEmpty ? nil : self.displayedImages
                    let platform = self.draft?.platformName ?? "Post"
                    let icon = self.draft?.platformIconName
                    let tags = self.draft?.hashtags ?? []
                    let heading = self.draft?.postHeading ?? ""
                    
                    let package = ScheduledPostData(
                        postHeading: heading,
                        platformName: platform,
                        iconName: icon,
                        caption: finalCaption,
                        images: finalImages,
                        hashtags: tags
                    )
                    
                    destinationVC.postData = package
                    destinationVC.captionText = captionTextView.text
                    destinationVC.postHeading = draft?.postHeading
                    
                    destinationVC.existingPostId = draft?.id
         
                    destinationVC.imageNames = draft?.images
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

class ShareTextSource: NSObject, UIActivityItemSource {
    let text: String

    init(text: String) {
        self.text = text
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {

        if activityType?.rawValue.contains("instagram") == true {
            return nil
        }
        return text
    }
}
