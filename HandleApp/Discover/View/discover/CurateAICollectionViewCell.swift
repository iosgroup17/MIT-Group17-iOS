//
//  CurateAICollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 28/01/26.
//

import UIKit

class CurateAICollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var cardContainer: UIView!
    @IBOutlet weak var createActionButton: UIButton!

    var didTapButtonAction: (() -> Void)?

    private let gradientLayer = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()

        cardContainer.applyHandleCardAppearance(cornerRadius: 20, shadowHost: shadowContainer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardContainer.refreshHandleCardAppearance(shadowHost: shadowContainer)
    }

//    private func setupGradient() {
//            
//        let colorTop = UIColor.white.withAlphaComponent(0.1).cgColor
//            let colorBottom = UIColor.systemTeal.withAlphaComponent(0.1).cgColor
//            gradientLayer.colors = [colorTop, colorBottom]
//            
//            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
//            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
//            
//            cardContainer.layer.insertSublayer(gradientLayer, at: 0)
//            
//            cardContainer.backgroundColor = .clear
//        }
//    
//    override func layoutSubviews() {
//            super.layoutSubviews()
//            // Force the gradient to match the exact size of the card container
//            gradientLayer.frame = cardContainer.bounds
//        }

    @IBAction func createButtonTapped(_ sender: UIButton) {
        didTapButtonAction?()
    }
}
