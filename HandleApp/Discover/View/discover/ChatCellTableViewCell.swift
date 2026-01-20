//
//  ChatCellTableViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 12/01/26.
//

import UIKit

class ChatCellTableViewCell: UITableViewCell {

    @IBOutlet weak var textView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var editorButton: UIButton!
    
    var onEditorButtonTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.layer.cornerRadius = 16
        textView.layer.masksToBounds = true
        // Initialization code
    }

    @IBAction func editorButtonTapped(_ sender: Any) {
            onEditorButtonTapped?()
        }
    
    func configureBubble(isUser: Bool) {
            if isUser {
                textView.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.2)
                messageLabel.textColor = .label
                textView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
            } else {
                textView.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.15)
                messageLabel.textColor = .label
                textView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            }

            textView.layer.borderWidth = 0.5
            textView.layer.borderColor = UIColor.separator.cgColor
        }
}
