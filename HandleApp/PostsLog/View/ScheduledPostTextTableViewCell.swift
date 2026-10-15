//
//  ScheduledPostTextTableViewCell.swift
//  HandleApp
//
//  Created by SDC_USER on 11/02/26.
//

import UIKit

class ScheduledPostTextTableViewCell: UITableViewCell {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
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

    func configure(with post: Post) {
        self.titleLabel.text = post.postHeading

        self.captionLabel.text = post.fullCaption

        if let iconName = post.platformIconName {
            platformIconImageView.image = UIImage(named: iconName)
            platformIconImageView.tintColor = .label
        } else {
            platformIconImageView.image = nil
        }

        if let scheduledDate = post.scheduledAt {
            dateLabel.text = ScheduledPostTextTableViewCell.dateFormatter.string(from: scheduledDate)
            timeLabel.text = ScheduledPostTextTableViewCell.timeFormatter.string(from: scheduledDate)
        } else {
            dateLabel.text = "No Date"
            timeLabel.text = "--:--"
        }
    }

}
