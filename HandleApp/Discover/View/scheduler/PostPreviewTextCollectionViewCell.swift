//
//  PostPreviewTextCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 11/02/26.
//

import UIKit

class PostPreviewTextCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var platformIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 12
        containerView.backgroundColor = .secondarySystemGroupedBackground
        // Optional Shadow
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowRadius = 4
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.masksToBounds = false
        // Initialization code
    }
    
    func configure(platformName: String, iconName: String?, caption: String) {
            titleLabel.text = platformName
            captionLabel.text = caption
            
            if let icon = iconName {
                platformIcon.image = UIImage(named: icon)
            } else {
                platformIcon.image = UIImage(systemName: "doc.text")
            }
        }

}
