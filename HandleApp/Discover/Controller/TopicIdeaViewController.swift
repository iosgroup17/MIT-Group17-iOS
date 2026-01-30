//
//  topicIdeaViewController.swift
//  HandleApp
//
//  Created by SDC-USER on 09/12/25.
//

import UIKit

class TopicIdeaViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var topicDetail: TopicDetail?
    var allPostDetails: [PostDetail] = []
    
    var pageTitle: String = "Topic Ideas"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = pageTitle
        
        collectionView.register(
            UINib(nibName: "TopicActionCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "TopicActionCollectionViewCell"
        )
        
        
        collectionView.register(
            UINib(nibName: "TopicDetailContextCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "TopicDetailContextCollectionViewCell"
        )
        
        collectionView.register(
            UINib(nibName: "PublishReadyImageCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "PublishReadyImageCollectionViewCell"
        )
        
        
        collectionView.register(
            UINib(nibName: "PublishReadyTextCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "PublishReadyTextCollectionViewCell"
        )
        
        collectionView.register(
            UINib(nibName: "HeaderCollectionReusableView", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "HeaderCollectionReusableView"
        )
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.collectionViewLayout = generateLayout()
        
    }
    
    func generateLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            if sectionIndex == 0 {
                
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(50)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(50)
                )
                
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 16, leading: 16, bottom: 24, trailing: 16
                )
                
                return section
            }
            
            if sectionIndex == 1 {
                
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(40)
                )
                
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                
                header.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -8, bottom: 0, trailing: 16)
                
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(80)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(80)
                )
                
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 12
                
                section.boundarySupplementaryItems = [header]
                
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16)
                return section
            }
            
            if sectionIndex == 2 {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(255)
                )
                
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(255)
                )
                
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.interGroupSpacing = 16
                
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(40)
                )
                
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                
                header.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -8, bottom: -8, trailing: 0)
                
                sectionLayout.boundarySupplementaryItems = [header]
                
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
                
                return sectionLayout
            }
            return nil
        }
    }
}

extension TopicIdeaViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let detail = topicDetail else { return 0 }
        
        if section == 0 {
            return 1 // The "What's this about" card
        } else if section == 1 {
            return detail.actions?.count ?? 0
        } else {
            return detail.relevantPosts?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TopicDetailContextCollectionViewCell",
                for: indexPath
            ) as! TopicDetailContextCollectionViewCell
            
            
            if let text = topicDetail?.contextDescription {
                cell.configure(with: text)
            }
            
            return cell
        }
        
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TopicActionCollectionViewCell",
                for: indexPath
            ) as! TopicActionCollectionViewCell
            
            
            if let actions = topicDetail?.actions, indexPath.row < actions.count {
                let action = actions[indexPath.row]
                cell.configure(with: action)
            }
            
            return cell
        }
        
        if indexPath.section == 2 {
            // 1. Safely get the post object
            guard let posts = topicDetail?.relevantPosts, indexPath.row < posts.count else {
                return UICollectionViewCell() // Return empty if data is missing
            }
            let post = posts[indexPath.row]
            
            // 2. Check if it has images (Array exists AND is not empty)
            // Note: post.postImage is [String]? so !images.isEmpty checks if it has items
            if let images = post.postImage, !images.isEmpty {
                
                // --- USE IMAGE CELL ---
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "PublishReadyImageCollectionViewCell", // Make sure this XIB is registered!
                    for: indexPath
                ) as! PublishReadyImageCollectionViewCell
                
                cell.configure(with: post)
                return cell
                
            } else {
                
                // --- USE TEXT CELL ---
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "PublishReadyTextCollectionViewCell", // Make sure this XIB is registered!
                    for: indexPath
                ) as! PublishReadyTextCollectionViewCell
                
                cell.configure(with: post)
                return cell
            }
        }
        
        return UICollectionViewCell()
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "HeaderCollectionReusableView",
            for: indexPath
        ) as! HeaderCollectionReusableView
        
        if indexPath.section == 1 {
            header.titleLabel.text = "Suggested Actions"
        } else if indexPath.section == 2 {
            header.titleLabel.text = "Posts for this Trend"
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            // Safely unwrap the array first
            guard let actions = topicDetail?.actions, indexPath.row < actions.count else { return }
            
            let action = actions[indexPath.row]
            
            if let urlString = action.destinationUrl, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
        
        if indexPath.section == 2 {
            
            guard let posts = topicDetail?.relevantPosts, indexPath.row < posts.count else { return }
            
            let previewPost = posts[indexPath.row]
            print("Selected ID: \(previewPost.id)")
            
            
            let fullDetail = allPostDetails.first(where: { $0.id == previewPost.id })
            
            
            let draft = EditorDraftData(
                platformName: fullDetail?.platformName ?? "LinkedIn",
                platformIconName: fullDetail?.platformIconId ?? previewPost.platformIcon,
                caption: fullDetail?.fullCaption ?? previewPost.caption,
                images: fullDetail?.images ?? previewPost.postImage,
                hashtags: fullDetail?.suggestedHashtags ?? previewPost.hashtags,
                postingTimes: fullDetail?.optimalPostingTimes ?? []
            )
            
            
            let storyboard = UIStoryboard(name: "Discover", bundle: nil)
            if let editorVC = storyboard.instantiateViewController(withIdentifier: "EditorSuiteViewController") as? EditorSuiteViewController {
                
                editorVC.draft = draft
                
                self.navigationController?.pushViewController(editorVC, animated: true)
            }
        }
    }
}
