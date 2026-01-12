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
    
    // Static formatter to avoid re-creating it for every cell (better performance)
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // e.g., 10:30 AM
        return formatter
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
        self.selectionStyle = .none
    }

    func configure(with post: Post) {
        // 1. Use postText to match your Supabase schema property
        postTextLabel.text = post.postText
        
        // 2. Format the Date object from 'scheduledAt' into a string
        if let scheduleDate = post.scheduledAt {
            timeLabel.text = PostTableViewCell.timeFormatter.string(from: scheduleDate)
        }
            
        // 3. Image mapping remains the same
        platformIconImageView.image = UIImage(named: post.platformIconName)
        thumbnailImageView.image = UIImage(named: post.imageName)
    }
}
