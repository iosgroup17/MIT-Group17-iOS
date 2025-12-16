//
//  topicIdeaViewController.swift
//  HandleApp
//
//  Created by SDC-USER on 09/12/25.
//

import UIKit

class TopicIdeaViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var currentTopicGroup: TopicIdeaGroup?
    var allPostDetails: [PostDetail] = []
    
    var pageTitle: String = "Topic Ideas"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = pageTitle
        
        let nib = UINib(nibName: "TopicIdeaCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "TopicIdeaCollectionViewCell")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.collectionViewLayout = generateLayout()
       // setupUI()
        
    }
    
    func generateLayout() -> UICollectionViewLayout {
            return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in

                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                      heightDimension: .absolute(240))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
 
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .absolute(240))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8)
                
                return section
            }
        }

}

extension TopicIdeaViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentTopicGroup?.ideas.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopicIdeaCollectionViewCell", for: indexPath) as? TopicIdeaCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if let idea = currentTopicGroup?.ideas[indexPath.row] {
            cell.configure(with: idea)
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            
            //Identify which idea was clicked
            guard let selectedIdea = currentTopicGroup?.ideas[indexPath.row] else { return }
            
            print("Selected ID: \(selectedIdea.id)")
            

            guard let detail = allPostDetails.first(where: { $0.id == selectedIdea.id }) else {
                print("❌ Details not found for ID: \(selectedIdea.id). Check your JSON IDs.")
                return
            }
            

            let draft = EditorDraftData(
                platformName: detail.platformName ?? "Instagram",
                platformIconName: detail.platformIconId ?? "icon-instagram",
                caption: detail.fullCaption ?? selectedIdea.caption, // Fallback to short caption
                images: detail.images ?? [selectedIdea.image].compactMap { $0 }, // Fallback to cover image
                hashtags: detail.suggestedHashtags ?? [],
                postingTimes: detail.optimalPostingTimes ?? []
            )
            

            let storyboard = UIStoryboard(name: "Discover", bundle: nil)
            if let editorVC = storyboard.instantiateViewController(withIdentifier: "EditorSuiteViewController") as? EditorSuiteViewController {
                
                editorVC.draft = draft
                
            self.navigationController?.pushViewController(editorVC, animated: true)
            }
        }
}
