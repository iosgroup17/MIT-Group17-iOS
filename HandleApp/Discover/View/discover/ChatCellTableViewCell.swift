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
                // USER: Purple bubble, tail on bottom-right
                // Round Top-Left, Top-Right, Bottom-Left. Keep Bottom-Right sharp.
                textView.backgroundColor = UIColor.secondarySystemBackground
                textView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
            } else {
                // BOT: Gray bubble, tail on bottom-left
                // Round Top-Left, Top-Right, Bottom-Right. Keep Bottom-Left sharp.
                textView.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.1) // or your custom color
                textView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            }
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            // Reset state so recycled cells don't show buttons wrongly
            editorButton?.isHidden = true
            onEditorButtonTapped = nil
        }

}
