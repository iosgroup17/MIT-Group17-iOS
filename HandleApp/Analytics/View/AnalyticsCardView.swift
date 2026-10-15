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
// awakefromnib is called when the view is loaded from a nib or storyboard file.
// awakefromnib is specifically for views loaded from nibs or storyboards and viewdidload is for view controllers. awakefromnib is used to perform additional setup or initialization for views after they have been loaded from a nib or storyboard. while viewdidload is used to set up the overall view hierarchy and configure the view controller's properties and behaviors.

    private func setupCardDesign() {
        applyHandleCardAppearance()
        clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshHandleCardAppearance()
    }
}
