//
//  PostsCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 30/03/26.
//

import UIKit

class PostsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var countLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = 0.1
        shadowContainer.layer.shadowRadius = 10
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowContainer.layer.cornerRadius = 12
        // Initialization code
    }
    
    func configure(type: String, count: Int) {
     
        if type == "Saved" {
            imageView.image = UIImage(systemName: "bookmark.fill")
            imageView.tintColor = .darkGray
            
            textLabel.text = "Saved"
            countLabel.text = "\(count) Posts"
        } else {
            imageView.image = UIImage(systemName: "calendar.badge.clock")
            imageView.tintColor = .systemGreen
            
            textLabel.text = "Scheduled"
            countLabel.text = "\(count) Posts"
        }
        
    }

}
