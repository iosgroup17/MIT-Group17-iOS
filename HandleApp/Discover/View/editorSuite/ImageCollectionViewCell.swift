//
//  ImageCollectionViewCell.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 28/11/25.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
    }

    func configure(with image: UIImage) {
            imageView.image = image
            imageView.backgroundColor = .clear
            imageView.tintColor = .clear 
        }
        
    func configureAsAddButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        imageView.image = UIImage(systemName: "plus", withConfiguration: config)
        
        imageView.backgroundColor = .systemGray5 
        imageView.tintColor = .darkGray        
        imageView.contentMode = .center        
    }
}
