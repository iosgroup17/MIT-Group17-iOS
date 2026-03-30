//
//  TrendingTopicHashtagCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 28/01/26.
//

import UIKit

class TrendingTopicHashtagCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var tagContainer: UIView!
    @IBOutlet weak var tagLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        tagContainer.layer.cornerRadius = 12
        // Initialization code
    }

    func configure(text: String) {
        tagLabel.text = text
        
        tagContainer.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.1)
        tagContainer.layer.borderWidth = 0
        tagLabel.textColor = .black
    }
    
}
