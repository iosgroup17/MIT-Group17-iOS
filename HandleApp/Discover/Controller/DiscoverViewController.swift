//
//  DiscoverViewController.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 25/11/25.
//

import UIKit
import Supabase

class DiscoverViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var ideasResponse = DiscoverIdeaResponse()
    var trendingTopics: [TrendingTopic] = []
    var publishReadyPosts: [PublishReadyPost] = []
    var topicDetails: [TopicDetail] = []
    
    var selectedPostDetails: [PostDetail] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        trendingTopics = ideasResponse.trendingTopics
        publishReadyPosts = ideasResponse.publishReadyPosts
        topicDetails = ideasResponse.topicDetails
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(
            UINib(nibName: "TrendingTopicCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "TrendingTopicCollectionViewCell"
        )
        
        
        collectionView.register(
            UINib(nibName: "CurateAICollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "CurateAICollectionViewCell"
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
            UINib(nibName: "FilterCellCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "FilterCellCollectionViewCell"
        )
        
        collectionView.register(
            UINib(nibName: "HeaderCollectionReusableView", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "HeaderCollectionReusableView"
        )
        
        
        
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
        
        
        Task {
            await loadSupabaseData()
        }
    }
    
    func loadSupabaseData() async {
        print("Starting Supabase Fetch ")
        
        do {
            
            let fetchedData = try await SupabaseManager.shared.loadPostsIdeas()
            
            await MainActor.run {
                print("Data Received. Updating UI...")
                
                self.ideasResponse = fetchedData
                
                self.trendingTopics = fetchedData.trendingTopics
                self.topicDetails = fetchedData.topicDetails
                
                self.publishReadyPosts = fetchedData.publishReadyPosts
                
                self.collectionView.reloadData()
            }
            
        } catch {
            print("Error loading data: \(error.localizedDescription)")
        }
    }
    
    func generateLayout() -> UICollectionViewLayout {
        
        return UICollectionViewCompositionalLayout { section, env -> NSCollectionLayoutSection? in
            
            if section == 0 {
                
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(175)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(180)
                )
                
                // Use .horizontal for horizontal flow ( L - R )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let sectionLayout = NSCollectionLayoutSection(group: group)
                
                
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(
                    top: 0, leading: 16, bottom: 10, trailing: 16
                )
                
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
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(222),
                    heightDimension: .absolute(168)
                )
                
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.orthogonalScrollingBehavior = .continuous
                sectionLayout.interGroupSpacing = 12
                sectionLayout.contentInsets = NSDirectionalEdgeInsets(
                    top: 4, leading: 16, bottom: 16, trailing: 16
                )
                
                sectionLayout.boundarySupplementaryItems = [header]
                
                return sectionLayout
                
            }
            
            if section == 2 {
                
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
    
extension DiscoverViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 3
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            if section == 0 { return 1 }
            if section == 1 { return trendingTopics.count }
            if section == 2 { return publishReadyPosts.count }
            
            return 0
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
            if indexPath.section == 0 {
                
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "CurateAICollectionViewCell",
                    for: indexPath
                ) as! CurateAICollectionViewCell
                
                return cell
                
            }
            
            
            if indexPath.section == 1 {
                
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "TrendingTopicCollectionViewCell",
                    for: indexPath
                ) as! TrendingTopicCollectionViewCell
                
                let idea = trendingTopics[indexPath.row]
                
                cell.configure(with: idea)
                
                return cell
              
            }
            
            if indexPath.section == 2 {
                let post = publishReadyPosts[indexPath.row]
                
                // Check if Image URL exists and is not empty
                if let img = post.postImage, !img.isEmpty {
                    // Use the Image Cell XIB
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: "PublishReadyImageCollectionViewCell",
                        for: indexPath
                    ) as! PublishReadyImageCollectionViewCell
                    
                    cell.configure(with: post)
                    return cell
                    
                } else {
                    // Use the Text Cell XIB
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: "PublishReadyTextCollectionViewCell",
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
                header.titleLabel.text = "Trending Topics"
            } else if indexPath.section == 2 {
                header.titleLabel.text = "Publish-Ready Posts For You"
            }
            
            return header
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            
            if indexPath.section == 0 {
                
                
                let storyboard = UIStoryboard(name: "Discover", bundle: nil) // Or "Main"
                if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? UserIdeaViewController {
                    self.navigationController?.pushViewController(chatVC, animated: true)
                } else {
                    print("ChatViewController not found in Storyboard")
                }
                return
            
            }
           
            if indexPath.section == 1 {
                
                let selectedTopic = trendingTopics[indexPath.row]
                //let selectedID = selectedTopic.id
                let selectedName = selectedTopic.topicName
                
                let matchingDetail = topicDetails.first(where: { $0.topicId == selectedTopic.id })
                        
                        if matchingDetail == nil {
                            print("ERROR: No detail found for topic: \(selectedTopic.topicName). Check Supabase IDs.")
                        }
                
                
                let storyboard = UIStoryboard(name: "Discover", bundle: nil)
                        if let destVC = storyboard.instantiateViewController(withIdentifier: "TopicIdeasVC") as? TopicIdeaViewController {

                            destVC.topicDetail = matchingDetail
                            destVC.allPostDetails = selectedPostDetails
                            destVC.pageTitle = selectedTopic.topicName
                            
                            navigationController?.pushViewController(destVC, animated: true)
                        }
                
                
                print("Selected Trending Topic: \(selectedName)")
                return
                
            }
            
            
            if indexPath.section == 2 {
                let selectedID = publishReadyPosts[indexPath.row].id
                
                // 2. Look up the full details from the separate array using that ID
                guard let fullDetails = ideasResponse.selectedPostDetails.first(where: { $0.id == selectedID }) else {
                    print("Error: Could not find details for ID: \(selectedID)")
                    return
                }
                
                // 3. Create the Draft Data
                let draft = EditorDraftData(
                    platformName: fullDetails.platformName ?? "Unknown",
                    platformIconName: fullDetails.platformIconId ?? "icon-instagram",
                    caption: fullDetails.fullCaption ?? "",
                    images: fullDetails.images ?? [],
                    hashtags: fullDetails.suggestedHashtags ?? [],
                    postingTimes: fullDetails.optimalPostingTimes ?? []
                )
                
                // 4. Perform Segue
                performSegue(withIdentifier: "ShowEditorSegue", sender: draft)
                return
            }
        }
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "ShowEditorSegue",
               let editorVC = segue.destination as? EditorSuiteViewController,
               let data = sender as? EditorDraftData {
                
                editorVC.draft = data
            }
        }
        
    }

