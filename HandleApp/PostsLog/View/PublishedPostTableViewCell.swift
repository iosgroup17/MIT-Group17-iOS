//
//  PublishedPostTableViewCell.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 27/11/25.
//

import UIKit

class PublishedPostTableViewCell: UITableViewCell {

    @IBOutlet weak var platformIconImageView: UIImageView!
    @IBOutlet weak var analyticsContainerView: UIView!
    @IBOutlet weak var engagementLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var repostsLabel: UILabel!
    @IBOutlet weak var sharesLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var postLabel: UILabel!
    @IBOutlet weak var analyticsHeightConstraint: NSLayoutConstraint!
    private let expandedHeight: CGFloat = 100
    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
        self.selectionStyle = .none
    }
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium   // "Oct 12, 2023"
        formatter.timeStyle = .short    // "10:30 AM"
        return formatter
    }()
    func configure(with post: Post, isExpanded: Bool) {
        // 1. Basic Content
        postLabel.text = post.postText
        platformIconImageView.image = UIImage(named: post.platformIconName)
        thumbnailImageView.image = UIImage(named: post.imageName)
        
        // 2. Simplified Date Handling
        // Using the 'published_at' timestamptz from Supabase
        if let publishDate = post.publishedAt {
            dateTimeLabel.text = PublishedPostTableViewCell.dateFormatter.string(from: publishDate)
        }
        // 3. Metrics (Now Ints from schema)
        likesLabel.text = "\(post.likes ?? 0)"
        commentsLabel.text = "\(post.comments ?? 0)"
        sharesLabel.text = "\(post.shares ?? 0)"
        repostsLabel.text = "\(post.reposts ?? 0)"
        viewsLabel.text = "\(post.views ?? 0)"
        engagementLabel.text = "\(post.engagementScore ?? 0)"
        
        // 5. Expansion Logic
        analyticsHeightConstraint.constant = isExpanded ? expandedHeight : 0
        analyticsContainerView.alpha = isExpanded ? 1.0 : 0.0
        
        // Update layout without animation here (animation is handled by the TableView)
        contentView.layoutIfNeeded()
    }

}
