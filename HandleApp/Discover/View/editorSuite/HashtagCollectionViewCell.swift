//
//  HashtagCollectionViewCell.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 27/11/25.
//

import UIKit

class HashtagCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var hashtagLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        containerView.layer.cornerRadius = 8
        containerView.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.15)
        hashtagLabel.textColor = .label
    }

    func configure(text: String) {
            hashtagLabel.text = text
        }

}
