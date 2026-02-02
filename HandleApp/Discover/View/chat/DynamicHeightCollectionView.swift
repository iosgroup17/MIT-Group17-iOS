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
        // This is the magic line: Ask the LAYOUT for the size, not the view
        return self.collectionViewLayout.collectionViewContentSize
    }
}
