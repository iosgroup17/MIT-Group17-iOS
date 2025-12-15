//
//  DiscoverViewController.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 25/11/25.
//

import UIKit

class DiscoverViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var ideasResponse = PostIdeasResponse()
    var topIdeas: [TopIdea] = []
    var trendingTopics: [TrendingTopic] = []
    var recommendations: [Recommendation] = []
    var allRecommendations: [Recommendation] = []
    var topicGroups: [TopicIdeaGroup] = []
    
    var currentPlatformFilter: String = "All" {
            didSet {
                applyFilter()
            }
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topIdeas = ideasResponse.topIdeas
        trendingTopics = ideasResponse.trendingTopics
        recommendations = ideasResponse.recommendations
        allRecommendations = ideasResponse.recommendations
        topicGroups = ideasResponse.topicIdeas
       
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(
                UINib(nibName: "TopIdeaCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "TopIdeaCollectionViewCell"
            )
        
        collectionView.register(
                    UINib(nibName: "TrendingCollectionViewCell", bundle: nil),
                    forCellWithReuseIdentifier: "TrendingCollectionViewCell"
                )
        
        collectionView.register(
                    UINib(nibName: "RecommendationsCollectionViewCell", bundle: nil),
                    forCellWithReuseIdentifier: "RecommendationsCollectionViewCell"
                )
        
        collectionView.register(
                UINib(nibName: "FilterCellCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "FilterCellCollectionViewCell"
            )
        
        collectionView.register(
            UINib(nibName: "HeaderCollectionReusableView", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "HeaderCollectionReusableView"
        )

        
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
    }

    func generateLayout() -> UICollectionViewLayout {
        
        return UICollectionViewCompositionalLayout { section, env -> NSCollectionLayoutSection? in
            
            // SECTION 0 — TOP IDEAS
            if section == 0 {
                
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
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(170),
                    heightDimension: .absolute(170)
                )
                
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.orthogonalScrollingBehavior = .continuous
                sectionLayout.interGroupSpacing = 18
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(
                    top: 4, leading: 16, bottom: 16, trailing: 16
                )
                
                sectionLayout.boundarySupplementaryItems = [header]
                
                return sectionLayout
            }
            
            if section == 1 {

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
                    widthDimension: .estimated(50),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(50)
                )
                
                // Use .horizontal for horizontal flow ( L - R )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                group.interItemSpacing = .fixed(5)
                
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.interGroupSpacing = 9
                
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(
                    top: 10, leading: 16, bottom: 20, trailing: 16
                )
                
                sectionLayout.boundarySupplementaryItems = [header]
                
                return sectionLayout
            }
            
            if section == 2 {
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let sectionLayout = NSCollectionLayoutSection(group: group)
                
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

                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                
                return sectionLayout
            }

            if section == 3 {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(167))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.interGroupSpacing = 20

                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                
                return sectionLayout
            }
            
            return nil
        }
    }

    func applyFilter() {
        //everything
        if currentPlatformFilter == "All" {
            recommendations = allRecommendations
        } else {
        // 2. Filter by name (Instagram, LinkedIn, X)
            recommendations = allRecommendations.filter { rec in
                return rec.platformIcon == currentPlatformFilter
            }
        }
        
        if let cv = collectionView {
            cv.reloadSections(IndexSet(integer: 3))
        }
    }

}

extension DiscoverViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, FilterCellDelegate{
    func didSelectFilter(filterName: String) {
            currentPlatformFilter = filterName
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return topIdeas.count }
        if section == 1 { return min(trendingTopics.count, 6) }
        if section == 2 { return 1 }
        if section == 3 { return recommendations.count }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: "TopIdeaCollectionViewCell",
                        for: indexPath
                    ) as! TopIdeaCollectionViewCell

                    let idea = topIdeas[indexPath.row]

                    cell.configure(
                        with: UIImage(named: idea.image),
                        caption: idea.caption,
                        platformIcon: UIImage(named: idea.platformIcon)
                    )

                    return cell
                }
        
        if indexPath.section == 1 {
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: "TrendingCollectionViewCell",
                        for: indexPath
                    ) as! TrendingCollectionViewCell
                    
                        let topic = trendingTopics[indexPath.row]
                        cell.configure(with: topic)
                    return cell
                }
        
        if indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCellCollectionViewCell", for: indexPath) as! FilterCellCollectionViewCell
            
            cell.delegate = self
            
            return cell
        }
 
        if indexPath.section == 3 {
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: "RecommendationsCollectionViewCell",
                        for: indexPath
                    ) as! RecommendationsCollectionViewCell
                    
                    let rec = recommendations[indexPath.row]
                    
                    cell.configure(
                        platform: rec.platformIcon,
                        image: UIImage(named: rec.image),
                        caption: rec.caption,
                        whyText: rec.whyThisPost
                    )
                    return cell
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

            if indexPath.section == 0 {
                header.titleLabel.text = "Top Post Ideas For You"
            } else if indexPath.section == 1 {
                header.titleLabel.text = "Trending Topics"
            } else if indexPath.section == 2 {
                header.titleLabel.text = "Recommended For You"
            }

            return header
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            
            if indexPath.section == 1 {
                let selectedTopic = trendingTopics[indexPath.row]
                let selectedID = selectedTopic.id
                let selectedName = selectedTopic.name
                
                if let selectedGroup = topicGroups.first(where: { $0.topicId == selectedID }) {
                    
                    let storyboard = UIStoryboard(name: "Discover", bundle: nil)
                    if let topicVC = storyboard.instantiateViewController(withIdentifier: "TopicIdeasVC") as? TopicIdeaViewController {
                        
                        // Data passing
                        topicVC.currentTopicGroup = selectedGroup
                        topicVC.allPostDetails = self.ideasResponse.selectedPostDetails
                        
                        // Title passing
                        topicVC.pageTitle = selectedName
                        
                        self.navigationController?.pushViewController(topicVC, animated: true)
                    }
                }
                return
            }
            
            var selectedID = ""
            
            // ID selection
            if indexPath.section == 0 {
                selectedID = topIdeas[indexPath.row].id
            } else if indexPath.section == 3 {
                selectedID = recommendations[indexPath.row].id
            } else {
                return
            }
            
            // List look up
            guard let fullDetails = ideasResponse.selectedPostDetails.first(where: { $0.id == selectedID }) else {
                print("Error: Could not find details for ID: \(selectedID)")
                return
            }
            

            let draft = EditorDraftData(
                platformName: fullDetails.platformName ?? "Unknown",
                platformIconName: fullDetails.platformIconId ?? "icon-instagram",
                caption: fullDetails.fullCaption ?? "",
                images: fullDetails.images ?? [],
                hashtags: fullDetails.suggestedHashtags ?? [],
                postingTimes: fullDetails.optimalPostingTimes ?? []
            )
            
            performSegue(withIdentifier: "ShowEditorSegue", sender: draft)
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "ShowEditorSegue",
               let editorVC = segue.destination as? EditorSuiteViewController,
               let data = sender as? EditorDraftData {
                
                editorVC.draft = data
            }
        }
  
}
