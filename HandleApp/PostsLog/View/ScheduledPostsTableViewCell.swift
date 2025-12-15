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
            
            // 1. Parse the timeString into a time Date object
            if let timePart = ScheduledPostsTableViewCell.timeFormatter.date(from: timeString) {
                
                let calendar = Calendar.current
                
                // 2. Extract components from the time part (hour, minute)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: timePart)
                // This is safer and more explicit than passing the DateComponents struct.
                if let hour = timeComponents.hour, let minute = timeComponents.minute {
                    
                    if let combinedDateTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: scheduledDate) {
                    
                        // 4. Format the final combined date/time object
                        dateTimeLabel.text = ScheduledPostsTableViewCell.dateFormatter.string(from: combinedDateTime)
                        
                    } else {
                        dateTimeLabel.text = "Time Combination Error" // Fallback if combining fails
                    }
                }
            } else {
                // If time parsing fails, show the raw scheduled date
                dateTimeLabel.text = ScheduledPostsTableViewCell.dateFormatter.string(from: scheduledDate)
            }
            
        }
    }

}
