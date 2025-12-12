//
//  FilterCellCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 10/12/25.
//

import UIKit

protocol FilterCellDelegate: AnyObject {
    func didSelectFilter(filterName: String)
}

class FilterCellCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "FilterCellCollectionViewCell"
    weak var delegate: FilterCellDelegate?

    @IBOutlet weak var buttonAll: UIButton!
    @IBOutlet weak var buttonInstagram: UIButton!
    @IBOutlet weak var buttonLinkedIn: UIButton!
    @IBOutlet weak var buttonX: UIButton!
    
    var allButtons: [UIButton] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        
        
        allButtons = [buttonAll, buttonInstagram, buttonLinkedIn, buttonX]
        setupDesign()
        // Initialization code
    }
    
    func setupDesign() {
        allButtons.forEach { btn in
            
            btn.layer.cornerRadius = 20
            btn.layer.masksToBounds = false
    
            btn.layer.shadowColor = UIColor.black.cgColor
            btn.layer.shadowOpacity = 0.1
            btn.layer.shadowOffset = CGSize(width: 0, height: 4)
            btn.layer.shadowRadius = 16
            
            btn.setTitleColor(.black, for: .normal)
        }
        
        // select "All" by default
        selectButton(buttonAll)
    }
    
    @IBAction func filterTapped(_ sender: UIButton) {
        var filterName = "All"
        
        if sender == buttonAll {
            filterName = "All"
        } else if sender == buttonInstagram {
            filterName = "Instagram"
        } else if sender == buttonLinkedIn {
            filterName = "LinkedIn"
        } else if sender == buttonX {
            filterName = "X"
        }
        selectButton(sender)
        
        delegate?.didSelectFilter(filterName: filterName)
    }

    
    func selectButton(_ selectedButton: UIButton) {
        for btn in allButtons {
            
            if btn == selectedButton {
                btn.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.25)
                btn.layer.borderWidth = 1
                btn.layer.borderColor = UIColor.systemTeal.cgColor
                btn.layer.shadowOpacity = 0.05
                
            } else {
                btn.backgroundColor = .white
                btn.layer.borderWidth = 1
                btn.layer.borderColor = UIColor.white.cgColor
                btn.layer.shadowOpacity = 0.15
            }
        }
    }
}
