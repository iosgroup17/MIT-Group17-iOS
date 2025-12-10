//
//  TrendingCollectionViewCell.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 26/11/25.
//

import UIKit

class TrendingCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var iconImage: UIImageView!
    
    @IBOutlet weak var topicLabel: UILabel!
    
    @IBOutlet weak var chevronImage: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        topicLabel.setContentHuggingPriority(.required, for: .horizontal)
            
        topicLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        
        layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.masksToBounds = false
        
        
        
        // INNER CARD APPEARANCE
        containerView.layer.cornerRadius = 10
        containerView.backgroundColor = .white
        containerView.clipsToBounds = true
    }
    
    func configure(with topic: TrendingTopic) {
        
        iconImage.image = UIImage(systemName: topic.icon)
        iconImage.tintColor = topic.color
        iconImage.backgroundColor = topic.color.withAlphaComponent(0.12)
        iconImage.layer.cornerRadius = 6
        iconImage.clipsToBounds = true


           // LABEL
        topicLabel.text = topic.name

       }

}
