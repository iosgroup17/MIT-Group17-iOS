//
//  DynamicHeightCollectionView.swift
//  HandleApp
//
//  Created by SDC-USER on 02/02/26.
//
import UIKit

class DynamicHeightCollectionView: UICollectionView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !self.bounds.size.equalTo(self.intrinsicContentSize) {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
  
        return self.collectionViewLayout.collectionViewContentSize
    }
}
