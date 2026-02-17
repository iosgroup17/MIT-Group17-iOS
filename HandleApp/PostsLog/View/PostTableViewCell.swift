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
                thumbnailImageView.image = UIImage(named: firstImage)
            } else {
                thumbnailImageView.image = nil
            }
        }
}
