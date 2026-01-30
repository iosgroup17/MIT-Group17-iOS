//
//  TopicDetailContextCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 30/01/26.
//

import UIKit

class TopicDetailContextCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var contextLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = 0.1
        shadowContainer.layer.shadowRadius = 10
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        cardView.layer.cornerRadius = 20

    }

    func configure(with description: String) {
        contextLabel.text = description
    }
    
}
