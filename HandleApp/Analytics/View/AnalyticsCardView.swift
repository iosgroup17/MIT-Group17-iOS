//
//  AnalyticsCardView.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 25/11/25.
//

import UIKit

class AnalyticsCardView: UIView {

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCardDesign()
    }
//
    
    private func setupCardDesign() {

        self.layer.cornerRadius = 16
        
        // 2. BORDER / STROKE
        // This adds a thin light grey outline
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.systemGray5.cgColor
        
        // 3. SHADOW 
        // "masksToBounds = false" means "Draw outside the lines"
        self.layer.masksToBounds = false
        self.clipsToBounds = false
        
        // Shadow Specs
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.10  // Visibility
        self.layer.shadowOffset = CGSize(width: 0, height: 4) // Push shadow down
        self.layer.shadowRadius = 6      // Blur amount
    }
}



