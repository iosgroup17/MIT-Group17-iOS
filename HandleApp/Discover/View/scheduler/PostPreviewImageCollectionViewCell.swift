//
//  PostPreviewImageCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 11/02/26.
//

import UIKit

class PostPreviewImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var platformIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 0.2
        containerView.layer.borderColor = UIColor.black.cgColor
        
        postImageView.layer.cornerRadius = 12
      
    
    }
    
    func configure(platformName: String, iconName: String?, caption: String, image: UIImage) {
        titleLabel.text = platformName
        captionLabel.text = caption
        postImageView.image = image
        
        if let icon = iconName {
            platformIcon.image = UIImage(named: icon)
        } else {
            platformIcon.image = UIImage(systemName: "photo")
        }
    }

}
