//
//  topicIdeaCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 09/12/25.
//

import UIKit

class TopicIdeaCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var shadowContainerView: UIView!
    
    @IBOutlet weak var cardView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var captionLabel: UILabel!
    
    @IBOutlet weak var platformIconView: UIImageView!
    
    @IBOutlet weak var badgeContainerView: UIView!
    
    @IBOutlet weak var badgeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.clipsToBounds = false
        self.contentView.clipsToBounds = false
                
        
        
        setupUI()
    }
    
    private func setupUI() {
            
            shadowContainerView.backgroundColor = .white
            shadowContainerView.layer.cornerRadius = 20
            shadowContainerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
            shadowContainerView.layer.shadowOpacity = 1
            shadowContainerView.layer.shadowRadius = 10
            shadowContainerView.layer.shadowOffset = .zero
       
//            cardView.backgroundColor = .white
//            cardView.layer.cornerRadius = 20
            
            badgeContainerView.layer.cornerRadius = 16
        
            imageView.layer.cornerRadius = 16
            
           
    }
    
    func configure(with idea: TopicIdea) {
            
            captionLabel.text = idea.caption
            badgeLabel.text = idea.whyThisPost
            
            
            if let image = UIImage(named: idea.image) {
                imageView.image = image
            } else {
                imageView.backgroundColor = .systemGray5 // Fallback
            }
            
            if let icon = UIImage(named: idea.platformIcon) {
                platformIconView.image = icon
            }
            
            
            let tealColor = UIColor(red: 0/255, green: 195/255, blue: 208/255, alpha: 1.0)
            badgeContainerView.backgroundColor = tealColor.withAlphaComponent(0.1)

        }

}
