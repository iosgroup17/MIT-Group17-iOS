//
//  ChatCellTableViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 12/01/26.
//

import UIKit

class ChatCellTableViewCell: UITableViewCell {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var editorButton: UIButton!
    
    var onEditorButtonTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func editorButtonTapped(_ sender: Any) {
            onEditorButtonTapped?()
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            // Reset state so recycled cells don't show buttons wrongly
            editorButton.isHidden = true
            onEditorButtonTapped = nil
        }

}
