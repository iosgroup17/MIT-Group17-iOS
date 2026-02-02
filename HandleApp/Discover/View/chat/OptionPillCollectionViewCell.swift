//
//  OptionPillCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 02/02/26.
//

import UIKit

class OptionPillCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var optionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        bgView.layer.cornerRadius = 16
        // Initialization code
    }
    
    func configure(with text: String) {
        optionLabel.text = text
        bgView.layer.borderWidth = 0
        }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                bgView.backgroundColor = .systemTeal.withAlphaComponent(0.1)
                bgView.layer.borderColor = UIColor.systemTeal.cgColor
                bgView.layer.borderWidth = 1
                optionLabel.textColor = .black
            } else {
                bgView.backgroundColor = .systemGray6
                optionLabel.textColor = .black
            }
        }
    }
    
}
