//
//  SavedPostsTableViewCell.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 26/11/25.
//

import UIKit

class SavedPostsTableViewCell: UITableViewCell {
    @IBOutlet weak var platformLabel: UILabel!
    @IBOutlet weak var postLabel: UILabel!
    @IBOutlet weak var thumbNailImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()

        thumbNailImage.layer.cornerRadius = 8
        thumbNailImage.clipsToBounds = true
        self.selectionStyle = .none
    }
    func configure(with post: Post) {
        self.platformLabel.text = post.platformName
        self.postLabel.text = post.text
        self.thumbNailImage.image = UIImage(named: post.imageName)
    }

}
