//
//  PublishedPostImageTableViewCell.swift
//  HandleApp
//
//  Created by SDC_USER on 17/02/26.
//

import UIKit

class PublishedPostImageTableViewCell: UITableViewCell {

    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func configure(with post: Post) {
        self.titleLabel.text = post.postHeading
  
        self.captionLabel.text = post.fullCaption
   
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
 
        if let publishedDate = post.publishedAt {
            dateLabel.text = PublishedPostImageTableViewCell.dateFormatter.string(from: publishedDate)
            timeLabel.text = PublishedPostImageTableViewCell.timeFormatter.string(from: publishedDate)
        } else {
            dateLabel.text = "No Date"
            timeLabel.text = "--:--"
        }
    }
    
}
