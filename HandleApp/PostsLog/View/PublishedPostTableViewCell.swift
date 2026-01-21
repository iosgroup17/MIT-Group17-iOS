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
    //Date and Time Formatter
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    func configure(with post: Post, isExpanded: Bool) {
        postLabel.text = post.postText
        platformIconImageView.image = UIImage(named: post.platformIconName)
        thumbnailImageView.image = UIImage(named: post.imageName)
        
        //Using the 'published_at' timestamptz from Supabase
        if let publishDate = post.publishedAt {
            dateTimeLabel.text = PublishedPostTableViewCell.dateFormatter.string(from: publishDate)
        }
        //Metrics
        likesLabel.text = "\(post.likes ?? 0)"
        commentsLabel.text = "\(post.comments ?? 0)"
        sharesLabel.text = "\(post.shares ?? 0)"
        repostsLabel.text = "\(post.reposts ?? 0)"
        viewsLabel.text = "\(post.views ?? 0)"
        engagementLabel.text = "\(post.engagementScore ?? 0)"
        
        //Expansion Logic
        analyticsHeightConstraint.constant = isExpanded ? expandedHeight : 0
        analyticsContainerView.alpha = isExpanded ? 1.0 : 0.0
        
        //Update layout
        contentView.layoutIfNeeded()
    }

}
