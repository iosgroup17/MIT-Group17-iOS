//
//  TopicActionCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 30/01/26.
//

import UIKit

class TopicActionCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var actionIcon: UIImageView!
    @IBOutlet weak var actionTitleLabel: UILabel!
    @IBOutlet weak var descritpionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = 0.1
        shadowContainer.layer.shadowRadius = 10
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        cardView.layer.cornerRadius = 20
        
        // Initialization code
    }
    
    func configure(with action: TopicAction) {
        actionTitleLabel.text = action.callToAction
        descritpionLabel.text = action.actionDescription
        
        if let iconName = action.actionIcon, !iconName.isEmpty {
            actionIcon.image = UIImage(systemName: iconName)
            actionIcon.tintColor = .systemTeal
        }
    }
    
}
