//
//  PublishReadyTextCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 28/01/26.
//

import UIKit

class PublishReadyTextCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var platformIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var hashtagCollectionView: UICollectionView!
    @IBOutlet weak var predictionView: UIView!
    @IBOutlet weak var predictionLabel: UILabel!
    
    var hashtags: [String] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        shadowContainer.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        shadowContainer.layer.shadowOpacity = 1
        shadowContainer.layer.shadowRadius = 10
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        cardView.layer.cornerRadius = 16
        
        predictionView.backgroundColor = .systemTeal.withAlphaComponent(0.1)
        predictionView.layer.cornerRadius = 16
        
        hashtagCollectionView.delegate = self
        hashtagCollectionView.dataSource = self
        
        hashtagCollectionView.register(UINib(nibName: "TrendingTopicHashtagCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TrendingTopicHashtagCollectionViewCell")
        // Initialization code
    }
    
    func configure(with post: PublishReadyPost) {
        titleLabel.text = post.postHeading
        captionLabel.text = post.caption
        predictionLabel.text = post.predictionText
        platformIcon.image = UIImage(named: post.platformIcon)
        
        self.hashtags = post.hashtags
        hashtagCollectionView.reloadData()
    }

}

extension PublishReadyTextCollectionViewCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashtags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendingTopicHashtagCollectionViewCell", for: indexPath) as! TrendingTopicHashtagCollectionViewCell
        
        cell.configure(text: hashtags[indexPath.row], isOutlined: true)
        
        return cell
        
    }
}

extension PublishReadyTextCollectionViewCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let rawText = "#\(hashtags[indexPath.row])"
  
        let font = UIFont.preferredFont(forTextStyle: .callout)
        let textAttributes = [NSAttributedString.Key.font: font]

        let textWidth = rawText.size(withAttributes: textAttributes).width
        
        let totalWidth = ceil(textWidth) + 16
        
        return CGSize(width: totalWidth, height: 27)
    }
}
