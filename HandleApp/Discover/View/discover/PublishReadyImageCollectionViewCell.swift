//
//  PublishReadyImageCollectionViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 28/01/26.
//

import UIKit

class PublishReadyImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var platformIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var hashtagCollectionView: UICollectionView!
    @IBOutlet weak var predictionView: UIView!
    @IBOutlet weak var predictionLabel: UILabel!
    
    var hashtags: [String] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = 0.1
        shadowContainer.layer.shadowRadius = 10
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        cardView.layer.cornerRadius = 20
        
        imageView.layer.cornerRadius = 16
        
        predictionView.backgroundColor = .systemTeal.withAlphaComponent(0.1)
        predictionView.layer.cornerRadius = 16
        
        hashtagCollectionView.delegate = self
        hashtagCollectionView.dataSource = self
        
        hashtagCollectionView.register(UINib(nibName: "TrendingTopicHashtagCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TrendingTopicHashtagCollectionViewCell")
    }

    func configure(with post: PublishReadyPost) {
        titleLabel.text = post.postHeading
        captionLabel.text = post.caption
        predictionLabel.text = post.predictionText
        platformIcon.image = UIImage(named: post.platformIcon)

        if let images = post.postImage, let firstImage = images.first {
                    
                    if firstImage.type == "stock" {
                        //load from assets using path
                        imageView.image = UIImage(named: firstImage.path)
                        
                    } else if firstImage.type == "custom" {
                        // fetch custom/user uplaoded images from supabase url
                        
                        imageView.image = UIImage(systemName: "photo")
                        
                        if let url = SupabaseManager.shared.getPublicURL(for: firstImage.path) {
                            Task {
                                do {
                                    let (data, _) = try await URLSession.shared.data(from: url)
                                    if let downloadedImage = UIImage(data: data) {
                                        await MainActor.run {
                                            self.imageView.image = downloadedImage
                                        }
                                    }
                                } catch {
                                    print("Failed to load image from URL: \(error)")
                                }
                            }
                        }
                    }
                } else {
                    imageView.image = nil 
                }
        
        self.hashtags = post.hashtags
        hashtagCollectionView.reloadData()
    }
    
}


extension PublishReadyImageCollectionViewCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashtags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendingTopicHashtagCollectionViewCell", for: indexPath) as! TrendingTopicHashtagCollectionViewCell
        
        cell.configure(text: hashtags[indexPath.row], isOutlined: true)
        
        return cell
        
    }
}

extension PublishReadyImageCollectionViewCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let rawText = "#\(hashtags[indexPath.row])"
  
        let font = UIFont.preferredFont(forTextStyle: .callout)
        let textAttributes = [NSAttributedString.Key.font: font]

        let textWidth = rawText.size(withAttributes: textAttributes).width
        
        let totalWidth = ceil(textWidth) + 12
        
        return CGSize(width: totalWidth, height: 27)
    }
}
