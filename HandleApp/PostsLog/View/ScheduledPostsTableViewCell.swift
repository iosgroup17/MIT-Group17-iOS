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
            formatter.dateFormat = "d MMM, h:mm a"
            return formatter
        }()
    private static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a" 
            return formatter
        }()
    func configure(with post: Post) {
        postsLabel.text = post.text
        platformIconImageView.image = UIImage(named: post.platformIconName)
        thumbnailImageView.image = UIImage(named: post.imageName)
        if let scheduledDate = post.date, let timeString = post.time, !timeString.isEmpty {
            if let timePart = ScheduledPostsTableViewCell.timeFormatter.date(from: timeString) {
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: timePart)
                if let hour = timeComponents.hour, let minute = timeComponents.minute {
                    if let combinedDateTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: scheduledDate) {
                        dateTimeLabel.text = ScheduledPostsTableViewCell.dateFormatter.string(from: combinedDateTime)
                    } else {
                        dateTimeLabel.text = "Time Combination Error" 
                    }
                }
            } else {
                dateTimeLabel.text = ScheduledPostsTableViewCell.dateFormatter.string(from: scheduledDate)
            }
            
        }
    }

}
