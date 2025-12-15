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
//awakefromnib is called when the view is loaded from a nib or storyboard file.
//awakefromnib is specifically for views loaded from nibs or storyboards and viewdidload is for view controllers. awakefromnib is used to perform additional setup or initialization for views after they have been loaded from a nib or storyboard. while viewdidload is used to set up the overall view hierarchy and configure the view controller's properties and behaviors.
    
    private func setupCardDesign() {

        self.layer.cornerRadius = 16
        
        // 2. BORDER / STROKE
        //Adding a thin light grey outline
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.systemGray5.cgColor
        
        // 3. SHADOW 
        // "masksToBounds = false" this is used because if true shadow will be clipped"
        self.layer.masksToBounds = false
        // clipstobounds false is used to allow shadow to be visible outside the view bounds
        self.clipsToBounds = false
        
        // Shadow Specs
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.10  // Visibility
        self.layer.shadowOffset = CGSize(width: 0, height: 4) // this will push shadow down
        self.layer.shadowRadius = 6      // it will specify the blur amount
    }
}



