//
//  RecommendationsCollectionViewCell.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 26/11/25.
//

import UIKit

class RecommendationsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var platformLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var tagContainerView: UIView!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var tagIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowView.layer.shadowRadius = 8
        shadowView.layer.shadowOpacity = 0.1


        cardView.layer.cornerRadius = 16
        //cardView.layer.masksToBounds = true
        
        postImageView.layer.cornerRadius = 12
        
        tagContainerView.layer.cornerRadius = 16
    }

    func configure(platform: String, image: UIImage?, caption: String, whyText: String) {
            
            // Basic Data Assignment
            platformLabel.text = "\(platform) Post"
            postImageView.image = image
            captionLabel.text = caption
            tagLabel.text = whyText
            
            // --- Platform Color & Icon Logic ---
            let themeColor: UIColor
                
                switch platform.lowercased() {
                case "instagram":
                    themeColor = UIColor(red: 225/255, green: 48/255, blue: 108/255, alpha: 1.0) // #E1306C
                case "linkedin":
                    themeColor = UIColor(red: 10/255, green: 102/255, blue: 194/255, alpha: 1.0) // #0A66C2
                case "x":
                    themeColor = .black
                default:
                    themeColor = .gray
                }
        
            
        tagContainerView.backgroundColor = themeColor.withAlphaComponent(0.1)
        tagLabel.textColor = themeColor
        tagIcon.tintColor = themeColor
        }
    
}
