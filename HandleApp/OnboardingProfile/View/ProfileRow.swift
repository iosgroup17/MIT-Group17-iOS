//
//  ProfileRow.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 27/11/25.
//

import UIKit

class ProfileRow: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var arrowIcon: UIImageView!
    @IBOutlet weak var separatorLine: UIView!
    
    var tapAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder){
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("ProfileRow", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    func configure(title: String, value: String, showIcon: Bool = true, titleColor: UIColor = .label, iconImage: UIImage? = nil) {
            titleLabel.text = title
            titleLabel.textColor = titleColor
            
        if let customIcon = iconImage {
                // Setup for Logout Style
                valueLabel.isHidden = true
                arrowIcon.isHidden = false
                arrowIcon.image = customIcon
                arrowIcon.tintColor = titleColor
            } else {
                // Setup for Standard Row
                if value.isEmpty {
                    valueLabel.text = "Add"
                    valueLabel.textColor = .systemTeal
                } else {
                    valueLabel.text = value
                    valueLabel.textColor = .systemGray
                }
                valueLabel.isHidden = false
                arrowIcon.isHidden = !showIcon
                arrowIcon.image = UIImage(systemName: "chevron.right")
                arrowIcon.tintColor = .systemGray3
            }
            
            self.isUserInteractionEnabled = true
        }
    
    @objc func handleTap(){
        tapAction?()
    }

}
