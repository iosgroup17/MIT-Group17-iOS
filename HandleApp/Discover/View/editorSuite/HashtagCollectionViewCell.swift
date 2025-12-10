//
//  HashtagCollectionViewCell.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 27/11/25.
//

import UIKit

class HashtagCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var hashtagLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        containerView.layer.cornerRadius = 8
        
        containerView.backgroundColor = UIColor(red: 0.85, green: 0.95, blue: 0.96, alpha: 1.0)
        
        hashtagLabel.textColor = .black
    }
    
    func configure(text: String) {
            hashtagLabel.text = text
        }

}
