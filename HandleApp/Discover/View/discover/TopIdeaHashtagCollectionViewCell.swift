//
//  TopIdeaHashtagCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import UIKit

class TopIdeaHashtagCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var hashtagContainer: UIView!
    @IBOutlet weak var hashtagText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        hashtagContainer.layer.cornerRadius = 4
        hashtagContainer.layer.masksToBounds = true
        
        hashtagText.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    }
    
    func configure(text: String, color: UIColor) {
        hashtagText.text = text
            
            // 2. Set Text Color (Solid Platform Color)
            hashtagText.textColor = color
            
            // 3. Set Background Color (Light Platform Color)
            hashtagContainer.backgroundColor = color.withAlphaComponent(0.1)
        }
}
