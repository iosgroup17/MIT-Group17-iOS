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
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        containerView.applyHandleCardAppearance(cornerRadius: 12, shadowHost: self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.refreshHandleCardAppearance(shadowHost: self)
    }

    func configure(platformName: String, iconName: String?, caption: String) {
        titleLabel.text = platformName
        captionLabel.text = caption

        if let icon = iconName {
            platformIcon.image = UIImage(named: icon)
            platformIcon.tintColor = .label
        } else {
            platformIcon.image = UIImage(systemName: "doc.text")
            platformIcon.tintColor = .secondaryLabel
        }
    }

}
