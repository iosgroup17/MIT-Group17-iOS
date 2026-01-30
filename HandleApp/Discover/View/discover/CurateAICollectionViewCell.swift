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
    override func awakeFromNib() {
        super.awakeFromNib()
        
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = 0.1
        shadowContainer.layer.shadowRadius = 12
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowContainer.layer.masksToBounds = false

        cardContainer.layer.cornerRadius = 20
        // Initialization code
    }

}
