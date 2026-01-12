//
//  ScheduledPostsTableViewCell.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 27/11/25.
//

import UIKit

class ScheduledPostsTableViewCell: UITableViewCell {

    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var platformIconImageView: UIImageView!
    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
        self.selectionStyle = .none
    }
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium   // "Oct 12, 2023"
        formatter.timeStyle = .short    // "10:30 AM"
        return formatter
    }()
    func configure(with post: Post) {
        // 1. Update text property name to match your schema
        postsLabel.text = post.postText
        
        platformIconImageView.image = UIImage(named: post.platformIconName)
        thumbnailImageView.image = UIImage(named: post.imageName)
        
        // 2. Simplified Date Handling
        // Using the 'scheduled_at' timestamp directly from the database
        if let scheduledDate = post.scheduledAt {
            // Use a formatter that shows both Date and Time (e.g., "Oct 12, 10:30 AM")
            dateTimeLabel.text = ScheduledPostsTableViewCell.dateFormatter.string(from: scheduledDate)
        } else {
            dateTimeLabel.text = "Unscheduled"
        }
    }
}
