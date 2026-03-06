//
//  ScheduledPostImageTableViewCell.swift
//  HandleApp
//
//  Created by SDC_USER on 11/02/26.
//

import UIKit

class ScheduledPostImageTableViewCell: UITableViewCell {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var platformIconImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
        self.selectionStyle = .none
        containerView.layer.borderWidth = 0.3
        containerView.layer.cornerRadius = 8
        containerView.layer.borderColor = UIColor.systemGray.cgColor
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    func configure(with post: Post) {
        self.titleLabel.text = post.postHeading

        self.captionLabel.text = post.fullCaption
        

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

        if let scheduledDate = post.scheduledAt {
            dateLabel.text = ScheduledPostImageTableViewCell.dateFormatter.string(from: scheduledDate)
            timeLabel.text = ScheduledPostImageTableViewCell.timeFormatter.string(from: scheduledDate)
        } else {
            dateLabel.text = "No Date"
            timeLabel.text = "--:--"
        }
    }
    
}
