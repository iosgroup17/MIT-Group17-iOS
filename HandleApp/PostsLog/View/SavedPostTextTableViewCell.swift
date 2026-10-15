//
//  SavedPostTextTableViewCell.swift
//  HandleApp
//
//  Created by SDC_USER on 11/02/26.
//

import UIKit

class SavedPostTextTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var platformIconImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        containerView.applyHandleCardAppearance(cornerRadius: 8)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.refreshHandleCardAppearance()
    }

    func configure(with post: Post) {

        self.titleLabel.text = post.postHeading

        self.captionLabel.text = post.fullCaption

        if let iconName = post.platformIconName {
            platformIconImageView.image = UIImage(named: iconName)
            platformIconImageView.tintColor = .label
        } else {
            platformIconImageView.image = nil
        }
    }
}
