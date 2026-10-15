//
//  SavedPostImageTableViewCell.swift
//  HandleApp
//
//  Created by SDC_USER on 11/02/26.
//

import UIKit

class SavedPostImageTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var platformIconImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
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
        if let images = post.imageNames, let firstImage = images.first {

                if firstImage.type == "stock" {
                    // 1. It's a stock image. Load from local assets using the 'path'
                    thumbnailImageView.image = UIImage(named: firstImage.path)

                } else if firstImage.type == "custom" {
                    // 2. It's a custom image! Fetch from Supabase URL

                    // Optional: Set a temporary placeholder while it downloads
                    thumbnailImageView.image = UIImage(systemName: "photo")

                    if let url = SupabaseManager.shared.getPublicURL(for: firstImage.path) {
                        Task {
                            do {
                                let (data, _) = try await URLSession.shared.data(from: url)
                                if let downloadedImage = UIImage(data: data) {
                                    await MainActor.run {
                                        // Update the cell's image on the main thread
                                        self.thumbnailImageView.image = downloadedImage
                                    }
                                }
                            } catch {
                            }
                        }
                    }
                }
            } else {
                thumbnailImageView.image = nil
            }
    }

}
