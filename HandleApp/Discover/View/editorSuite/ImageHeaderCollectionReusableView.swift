//
//  ImageHeaderCollectionReusableView.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 28/11/25.
//

import UIKit

class ImageHeaderCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
    }
    
}
