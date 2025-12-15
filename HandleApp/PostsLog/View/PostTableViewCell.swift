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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
        self.selectionStyle = .none
    }

    func configure(with post: Post) {
        postTextLabel.text = post.text
        timeLabel.text = post.time
            
        platformIconImageView.image = UIImage(named: post.platformIconName)
        thumbnailImageView.image = UIImage(named: post.imageName)
    }
}
