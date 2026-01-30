//
//  TrendingTopicCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 28/01/26.
//

import UIKit

class TrendingTopicCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var platformIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var hashtagsCollectionView: UICollectionView!
    
    var hashtags: [String] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cardView.layer.cornerRadius = 20

        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowContainer.layer.shadowRadius = 8
        shadowContainer.layer.shadowOpacity = 0.1
        shadowContainer.layer.masksToBounds = false
        
        hashtagsCollectionView.delegate = self
        hashtagsCollectionView.dataSource = self
        
        descriptionLabel.textColor = .darkGray
        
        hashtagsCollectionView.register(UINib(nibName: "TrendingTopicHashtagCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TrendingTopicHashtagCollectionViewCell")

        // Initialization code
    }
    
    func configure (with topic: TrendingTopic) {
        titleLabel.text = topic.topicName
        descriptionLabel.text = topic.shortDescription
        platformIcon.image = UIImage(named: topic.platformIcon)
        
        self.hashtags = topic.hashtags
        hashtagsCollectionView.reloadData()
        
    }

}


extension TrendingTopicCollectionViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashtags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendingTopicHashtagCollectionViewCell", for: indexPath) as! TrendingTopicHashtagCollectionViewCell
                
        cell.configure(text: hashtags[indexPath.row], isOutlined: false)
        
        return cell
    }
    
}


extension TrendingTopicCollectionViewCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let rawText = "#\(hashtags[indexPath.row])"
  
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        let textAttributes = [NSAttributedString.Key.font: font]

        let textWidth = rawText.size(withAttributes: textAttributes).width
        
        let totalWidth = ceil(textWidth) + 16
        
        return CGSize(width: totalWidth, height: 27)
    }
}
