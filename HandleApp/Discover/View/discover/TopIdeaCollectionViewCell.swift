//
//  TopIdea2CollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 16/12/25.
//

import UIKit

class TopIdeaCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var platformIcon: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var tagContainer: UIView!
    @IBOutlet weak var hashtagCollectionView: UICollectionView!
    
    var hashtags: [String] = []
    var currentThemeColor: UIColor = .gray
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        shadowContainer.layer.cornerRadius = 12
        
        shadowContainer.layer.masksToBounds = false
        
        shadowContainer.backgroundColor = .systemBackground
        
        shadowContainer.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        shadowContainer.layer.shadowOpacity = 1
        shadowContainer.layer.shadowRadius = 32
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        // shadowContainer.layer.shadowOffset = .zero
        
        
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        
        tagContainer.layer.cornerRadius = 8
        
        hashtagCollectionView.delegate = self
        hashtagCollectionView.dataSource = self
        
        let nib = UINib(nibName: "TopIdeaHashtagCollectionViewCell", bundle: nil)
        hashtagCollectionView.register(nib, forCellWithReuseIdentifier: "TopIdeaHashtagCollectionViewCell")
    }
    
    func configure(imageName: String, caption: String, hashtags: [String], platform: String) {
        
        imageView.image = UIImage(named: imageName)
        captionLabel.text = caption
        self.hashtags = hashtags
        
        
        let platformKey = platform.lowercased()
                
                if platformKey.contains("instagram") {
                    currentThemeColor = UIColor(red: 225/255, green: 48/255, blue: 108/255, alpha: 1.0)
                    platformIcon.image = UIImage(named: "icon-instagram") // Ensure Asset name matches
                    
                } else if platformKey.contains("linkedin") {
                    currentThemeColor = UIColor(red: 10/255, green: 102/255, blue: 194/255, alpha: 1.0)
                    platformIcon.image = UIImage(named: "icon-linkedin")
                    
                } else if platformKey.contains("x") || platformKey.contains("twitter") {
                    currentThemeColor = .systemTeal
                    platformIcon.image = UIImage(named: "icon-twitter")
                    
                } else {
                    currentThemeColor = .gray
                    platformIcon.image = UIImage(named: "icon-default")
                }
                
                hashtagCollectionView.reloadData()
            }
}

extension TopIdeaCollectionViewCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashtags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopIdeaHashtagCollectionViewCell", for: indexPath) as? TopIdeaHashtagCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(text: hashtags[indexPath.row], color: currentThemeColor)
        
        return cell
    }
}

extension TopIdeaCollectionViewCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // Inside the extension: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 1. Get the text exactly as it appears in the cell
        // (Note: We add the # manually here to measure the full string width)
        let rawText = hashtags[indexPath.row]
        let textToMeasure = rawText
        
        // 2. IMPORTANT: This font MUST match the font set in your XIB file.
        // If your XIB uses "System Semibold 12.0", this must be .semibold.
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        
        // 3. Calculate the exact width required for the text
        let textAttributes = [NSAttributedString.Key.font: font]
        let textWidth = textToMeasure.size(withAttributes: textAttributes).width
        
        // 4. Add Padding
        // 16 points for leading/trailing constraints (e.g. 8 left + 8 right)
        // + 10 extra buffer to be safe.
        let totalWidth = ceil(textWidth)
        
        return CGSize(width: totalWidth, height: 26)
    }
}
