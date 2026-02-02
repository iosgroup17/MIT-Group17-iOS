//
//  ChatOptionsTableViewCell.swift
//  HandleApp
//
//  Created by SDC-USER on 02/02/26.
//

import UIKit

class ChatOptionsTableViewCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: DynamicHeightCollectionView!
    
    var options: [String] = []
    
    var onOptionSelected: ((String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(
            UINib(nibName: "OptionPillCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "OptionPillCollectionViewCell"
        )
        // Setup Left-Aligned Flow Layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 6
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        // Add section insets so pills don't touch the edges perfectly
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = layout
        
        // Disable scrolling so it acts like a static view
        collectionView.isScrollEnabled = false

        // Initialization code
    }
    
    func configure(with options: [String]) {
            self.options = options
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded() // Calculate positions immediately
        }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        //1. Force layout calculation based on your desired width (250)
        // We use 250 because that's what we set in the XIB
        let fixedWidth: CGFloat = 250
        
        self.collectionView.frame = CGRect(x: 0, y: 0, width: fixedWidth, height: 10000)
        self.collectionView.layoutIfNeeded()
        
        // 2. Calculate height
        let contentSize = self.collectionView.collectionViewLayout.collectionViewContentSize
        
        // 3. Return the calculated size
        return CGSize(width: fixedWidth, height: contentSize.height + 24)
        }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionPillCollectionViewCell", for: indexPath) as! OptionPillCollectionViewCell
        cell.configure(with: options[indexPath.row])
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedText = options[indexPath.row]
        onOptionSelected?(selectedText)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
