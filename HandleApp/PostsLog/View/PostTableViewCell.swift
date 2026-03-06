//
//  PostTableViewCell.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 25/11/25.
//

import UIKit
class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var postTextLabel: UILabel!
    @IBOutlet weak var platformIconImageView: UIImageView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    //Date and Time Formatter
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" 
        return formatter
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
        self.selectionStyle = .none
    }

    func configure(with post: Post) {
    
            if let scheduleDate = post.scheduledAt {
                timeLabel.text = PostTableViewCell.timeFormatter.string(from: scheduleDate)
            } else {
                timeLabel.text = ""
            }
        
            if let iconName = post.platformIconName {
                platformIconImageView.image = UIImage(named: iconName)
            } else {
                platformIconImageView.image = nil
            }
            
        if let images = post.imageNames, let firstImage = images.first {
                
                if firstImage.type == "stock" {
                    // 1. It's a stock image. Load from local assets using the 'path'
                    thumbnailImageView.image = UIImage(named: firstImage.path)
                    
                } else if firstImage.type == "custom" {
                    // 2. It's a custom image! Fetch from Supabase URL
                    
                    // Optional: Set a temporary placeholder while it downloads
                    thumbnailImageView.image = UIImage(systemName: "photo")
                    
                    if let url = SupabaseManager.shared.getPublicURL(for: firstImage.path) {
                        Task {
                            do {
                                let (data, _) = try await URLSession.shared.data(from: url)
                                if let downloadedImage = UIImage(data: data) {
                                    await MainActor.run {
                                        // Update the cell's image on the main thread
                                        self.thumbnailImageView.image = downloadedImage
                                    }
                                }
                            } catch {
                                print("Failed to load thumbnail from URL: \(error)")
                            }
                        }
                    }
                }
            } else {
                thumbnailImageView.image = nil
            }
        }
}
