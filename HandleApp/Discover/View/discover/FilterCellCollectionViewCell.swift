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
            btn.layer.shadowRadius = 32
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
                btn.backgroundColor = UIColor(red: 0.29, green: 0.69, blue: 0.75, alpha: 1.0)
                btn.setTitleColor(.white, for: .normal)
                btn.layer.shadowOpacity = 0.05
                
            } else {
                btn.backgroundColor = .white
                btn.setTitleColor(.black, for: .normal)
                btn.layer.shadowOpacity = 0.15
            }
        }
    }
}
