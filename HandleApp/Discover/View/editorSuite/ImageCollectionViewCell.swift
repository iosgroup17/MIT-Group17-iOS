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
        // Initialization code
    }

    func configure(with image: UIImage) {
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = .clear
            imageView.tintColor = .clear // Remove tint if any
        }
        
    func configureAsAddButton() {
        // Use the system "+" icon
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        imageView.image = UIImage(systemName: "plus", withConfiguration: config)
        
        // Styling: Grey box, centered icon
        imageView.backgroundColor = .systemGray5 // The "Grey Box"
        imageView.tintColor = .darkGray        // The "+" color
        imageView.contentMode = .center        // Keep icon centered, don't stretch it
    }
}
