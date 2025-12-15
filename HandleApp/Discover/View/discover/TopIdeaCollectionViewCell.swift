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
        
            ShadowContainer.layer.cornerRadius = 20
            
            ShadowContainer.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
            ShadowContainer.layer.shadowOpacity = 1
            ShadowContainer.layer.shadowRadius = 32
            ShadowContainer.layer.shadowOffset = .zero


    }
    
    func configure(with image: UIImage?, caption: String, platformIcon: UIImage?) {
        
        ShadowContainer.layer.cornerRadius = 20
        //cardView.layer.masksToBounds = true
        
        
        mainImageView.image = image
        mainImageView.layer.cornerRadius = 16

        
        
        captionLabel.text = caption
        captionLabel.numberOfLines = 0
        
        
        platformIconView.image = platformIcon
        platformIconView.layer.cornerRadius = 4

    }


}
