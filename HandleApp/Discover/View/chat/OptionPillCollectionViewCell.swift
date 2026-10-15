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

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        bgView.layer.cornerRadius = 16
        // Initialization code
    }

    func configure(with text: String) {
        optionLabel.text = text
        updateAppearance()
    }

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    private func updateAppearance() {
        bgView.backgroundColor = isSelected ? UIColor.systemTeal.withAlphaComponent(0.1) : .secondarySystemGroupedBackground
        bgView.layer.borderWidth = isSelected ? 1 : 0
        bgView.layer.borderColor = isSelected ? UIColor.systemTeal.cgColor : UIColor.clear.cgColor
        optionLabel.textColor = .label
    }

}
