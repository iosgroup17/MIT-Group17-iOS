//
//  PublishedPostTableViewCell.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 27/11/25.
//

import UIKit

class PublishedPostTableViewCell: UITableViewCell {

    @IBOutlet weak var platformIconImageView: UIImageView!
    @IBOutlet weak var analyticsContainerView: UIView!
    @IBOutlet weak var engagementLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var repostsLabel: UILabel!
    @IBOutlet weak var sharesLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var postLabel: UILabel!
    @IBOutlet weak var analyticsHeightConstraint: NSLayoutConstraint!
    private let expandedHeight: CGFloat = 100
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
    func configure(with post: Post, isExpanded: Bool) {
            postLabel.text = post.text
        platformIconImageView.image = UIImage(named: post.platformIconName)
        thumbnailImageView.image = UIImage(named: post.imageName)
        if let scheduledDate = post.date, let timeString = post.time, !timeString.isEmpty {
            if let timePart = PublishedPostTableViewCell.timeFormatter.date(from: timeString) {
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: timePart)
                if let hour = timeComponents.hour, let minute = timeComponents.minute {
                    if let combinedDateTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: scheduledDate) {
                        dateTimeLabel.text = PublishedPostTableViewCell.dateFormatter.string(from: combinedDateTime)
                    } else {
                        dateTimeLabel.text = "Time Combination Error" 
                    }
                }
            } else {
                dateTimeLabel.text = PublishedPostTableViewCell.dateFormatter.string(from: scheduledDate)
            }
            
        }
        likesLabel.text = "\(post.likes ?? "")"
        commentsLabel.text = "\(post.comments ?? "")"
        sharesLabel.text = "\(post.shares ?? "")"
        repostsLabel.text = "\(post.reposts ?? "")"
        viewsLabel.text = "\(post.views ?? "")"
        engagementLabel.text = "\(post.engagementScore ?? "")"
        analyticsHeightConstraint.constant = isExpanded ? expandedHeight : 0
        analyticsContainerView.alpha = isExpanded ? 1.0 : 0.0
        
        contentView.layoutIfNeeded()
    }

}
