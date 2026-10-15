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

        cardView.applyHandleCardAppearance(cornerRadius: 16, shadowHost: shadowContainer)

        predictionView.layer.cornerRadius = 16
        predictionView.backgroundColor = .tertiarySystemFill
        predictionLabel.textColor = .secondaryLabel
        hashtagCollectionView.backgroundColor = .clear

        hashtagCollectionView.delegate = self
        hashtagCollectionView.dataSource = self

        hashtagCollectionView.register(UINib(nibName: "TrendingTopicHashtagCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TrendingTopicHashtagCollectionViewCell")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.refreshHandleCardAppearance(shadowHost: shadowContainer)
    }

    func configure(with post: PublishReadyPost) {
        titleLabel.text = post.postHeading
        captionLabel.text = post.caption
        predictionLabel.text = post.predictionText
        platformIcon.image = UIImage(named: post.platformIcon)
        platformIcon.tintColor = .label

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

        cell.configure(text: hashtags[indexPath.row])

        return cell

    }
}

extension PublishReadyTextCollectionViewCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let rawText = "#\(hashtags[indexPath.row])"

        let font = UIFont.preferredFont(forTextStyle: .callout)
        let textAttributes = [NSAttributedString.Key.font: font]

        let textWidth = rawText.size(withAttributes: textAttributes).width

        let totalWidth = ceil(textWidth) + 12

        return CGSize(width: totalWidth, height: 27)
    }
}
