//
//  TopIdea2CollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 16/12/25.
//

import UIKit

class TopIdeaCollectionViewCell: UICollectionViewCell {

        @IBOutlet weak var shadowContainer: UIView!
        @IBOutlet weak var imageView: UIImageView!
        @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var tagContainer: UIView!
    @IBOutlet weak var tagLabel: UILabel!
        
        override func awakeFromNib() {
            super.awakeFromNib()
            
            shadowContainer.layer.cornerRadius = 12
            
            shadowContainer.layer.masksToBounds = false
            
            shadowContainer.backgroundColor = .systemBackground
            
            shadowContainer.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
            shadowContainer.layer.shadowOpacity = 1
            shadowContainer.layer.shadowRadius = 32
            shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)

           // shadowContainer.layer.shadowOffset = .zero

            
            imageView.layer.cornerRadius = 12
            imageView.layer.masksToBounds = true
            
            tagContainer.layer.cornerRadius = 10
      
        }
        
        func configure(imageName: String, caption: String, whyText: String, platform: String) {

            imageView.image = UIImage(named: imageName)
            captionLabel.text = caption
            tagLabel.text = whyText
            
            let themeColor: UIColor
            
            let platformKey = platform.lowercased()
            
            if platformKey.contains("instagram") {
                
                themeColor = UIColor(red: 225/255, green: 48/255, blue: 108/255, alpha: 1.0)
                
            } else if platformKey.contains("linkedin") {
                
                themeColor = UIColor(red: 10/255, green: 102/255, blue: 194/255, alpha: 1.0)
                
            } else if platformKey.contains("x") || platformKey.contains("twitter") {
                
                themeColor = .black
                
            } else {
                themeColor = .gray
            }

            tagLabel.textColor = themeColor
            tagContainer.backgroundColor = themeColor.withAlphaComponent(0.1)
        }
        

}
