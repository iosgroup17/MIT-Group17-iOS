//
//  topicIdeaViewController.swift
//  HandleApp
//
//  Created by SDC-USER on 09/12/25.
//

import UIKit

class TopicIdeaViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var topic: TrendingTopic?
    var generatedPosts: [PublishReadyPost] = []
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
        generateContentForTopic()
        
    }
    
    func generateContentForTopic() {
            guard let currentTopic = topic else { return }
            
            // Construct a clear string for the AI to understand the trend
            let trendContextString = "\(currentTopic.topicName): \(currentTopic.shortDescription). Context: \(currentTopic.trendingContext ?? "")"
            
            self.showLoading() // Reuse your existing loading indicator
            
            Task {
                // 1. Fetch User Context (needed for the engine)
                let userProfile = await SupabaseManager.shared.fetchUserProfile() ?? UserProfile(
                    professionalIdentity: ["Content Creator"],
                    currentFocus: ["Growth"],
                    industry: ["General"],
                    primaryGoals: ["Engagement"],
                    contentFormats: ["Tips"],
                    platforms: ["LinkedIn"],
                    targetAudience: ["Professionals"],
                    
                )
                
                do {
                    // 2. Call the Foundation Model Engine
                    print("🤖 Generating posts for topic: \(currentTopic.topicName)")
                    let aiPosts = try await OnDevicePostEngine.shared.generatePublishReadyPosts(
                        trendText: trendContextString,
                        context: userProfile
                    )
                    
                    // 3. Update UI
                    await MainActor.run {
                        self.generatedPosts = aiPosts
                        // Reload only the "Posts" section (Section 2)
                        self.collectionView.reloadSections(IndexSet(integer: 2))
                        self.hideLoading()
                    }
                    
                } catch {
                    print("Error generating topic posts: \(error)")
                    await MainActor.run {
                        self.hideLoading()
                    }
                }
            }
        }
    
    func showLoading() {
            let alert = UIAlertController(title: nil, message: "Generating posts...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 20, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .medium
            loadingIndicator.startAnimating()
            alert.view.addSubview(loadingIndicator)
            present(alert, animated: true, completion: nil)
        }
    

    func hideLoading() {
        dismiss(animated: true, completion: nil)
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
                    heightDimension: .absolute(96)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(96)
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
        guard let data = topic else { return 0 }
        
        if section == 0 {
            return 1 
        } else if section == 1 {
            return data.actions?.count ?? 0
        } else {
            return generatedPosts.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TopicDetailContextCollectionViewCell",
                for: indexPath
            ) as! TopicDetailContextCollectionViewCell
            
            
            if let text = topic?.trendingContext {
                            cell.configure(with: text)
                        }
            
            return cell
        }
        
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TopicActionCollectionViewCell",
                for: indexPath
            ) as! TopicActionCollectionViewCell
            
            
            if let actions = topic?.actions, indexPath.row < actions.count {
                let action = actions[indexPath.row]
                cell.configure(with: action)
            }
            
            return cell
        }
        
        if indexPath.section == 2 {
            // [CHANGED] Use generatedPosts array
            guard indexPath.row < generatedPosts.count else { return UICollectionViewCell() }
            let post = generatedPosts[indexPath.row]
            
            // Logic to choose Image vs Text cell
            if let images = post.postImage, !images.isEmpty {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "PublishReadyImageCollectionViewCell",
                    for: indexPath
                ) as! PublishReadyImageCollectionViewCell
                
                cell.configure(with: post)
                return cell
            } else {
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
            header.titleLabel.text = "Suggested Actions"
        } else if indexPath.section == 2 {
            header.titleLabel.text = "Posts for this Trend"
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {

            guard let actions = topic?.actions, indexPath.row < actions.count else { return }
            
            let action = actions[indexPath.row]
            
            if let urlString = action.destinationUrl, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
        if indexPath.section == 2 {
            guard indexPath.row < generatedPosts.count else { return }
            let previewPost = generatedPosts[indexPath.row] // Get from local array

            self.showLoading()

            Task {
                do {
  
                    guard let profile = await SupabaseManager.shared.fetchUserProfile() else {
                        await MainActor.run { self.hideLoading() }
                        return
                    }
         
                    let finalDraft = try await OnDevicePostEngine.shared.refinePostForEditor(
                        post: previewPost,
                        context: profile
                    )

                    await MainActor.run {
                        self.hideLoading()
                        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
                        if let editorVC = storyboard.instantiateViewController(withIdentifier: "EditorModalEntry") as? EditorSuiteViewController {
                            editorVC.draft = finalDraft
                            self.navigationController?.pushViewController(editorVC, animated: true)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.hideLoading()
                        print("Error generating draft: \(error)")
                    }
                }
            }
        }
    }
}
