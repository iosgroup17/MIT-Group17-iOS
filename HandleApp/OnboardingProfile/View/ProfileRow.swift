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
    @IBOutlet weak var actionSwitch: UISwitch!
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
    
    func configure(title: String, value: String, isToggle: Bool = false, isConnected: Bool = false, showIcon: Bool = true){
        titleLabel.text = title
        
        if isToggle {
            valueLabel.isHidden = true
            actionSwitch.isHidden = false
            arrowIcon.isHidden = true
            actionSwitch.addTarget(self, action: #selector(handleSwitchChange), for: .valueChanged)
            actionSwitch.isOn = isConnected
            
            self.isUserInteractionEnabled = true
        } else {
            if value.isEmpty {
                valueLabel.text = "Add"
                valueLabel.textColor = .systemTeal
            } else {
                valueLabel.text = value
                valueLabel.textColor = .systemGray
            }
            
            valueLabel.isHidden = false
            arrowIcon.isHidden = !showIcon
            actionSwitch.isHidden = true
            
            self.isUserInteractionEnabled = true
        }
    }
    
    @objc func handleSwitchChange() {
        tapAction?()
    }
    
    @objc func handleTap(){
        if actionSwitch.isHidden{
            tapAction?()
        }
    }

}
