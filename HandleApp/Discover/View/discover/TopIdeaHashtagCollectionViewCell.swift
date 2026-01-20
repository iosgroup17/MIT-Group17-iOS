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
        if color == .systemTeal {
            hashtagText.text = text
            hashtagText.textColor = .black
            hashtagContainer.backgroundColor = color.withAlphaComponent(0.1)
        } else {
            hashtagText.text = text
            hashtagText.textColor = color
            hashtagContainer.backgroundColor = color.withAlphaComponent(0.075)
        }
    }
}
