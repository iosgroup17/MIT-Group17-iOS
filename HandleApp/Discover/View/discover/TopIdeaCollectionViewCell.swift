//
//  TopIdeaCollectionViewCell.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 25/11/25.
//

import UIKit

class TopIdeaCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var ShadowContainer: UIView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var platformIconView: UIImageView!


    override func awakeFromNib() {
        super.awakeFromNib()
        
            // SHADOW CONTAINER
            ShadowContainer.layer.cornerRadius = 20
            ShadowContainer.backgroundColor = .white // Required for shadow
            
            // Figma shadow (converted perfectly)
            ShadowContainer.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
            ShadowContainer.layer.shadowOpacity = 1
            ShadowContainer.layer.shadowRadius = 32
            ShadowContainer.layer.shadowOffset = .zero


    }
    
    func configure(with image: UIImage?, caption: String, platformIcon: UIImage?) {
        
        // CARD VIEW
        ShadowContainer.layer.cornerRadius = 20
        //cardView.layer.masksToBounds = true
        
        // IMAGE VIEW
        mainImageView.image = image
        mainImageView.layer.cornerRadius = 16
        mainImageView.layer.masksToBounds = true
        
        // CAPTION LABEL
        captionLabel.text = caption
        captionLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        captionLabel.numberOfLines = 0
        
        // PLATFORM ICON (small square logo beside label)
        platformIconView.image = platformIcon
        platformIconView.layer.cornerRadius = 4
        platformIconView.layer.masksToBounds = true
    }


}
