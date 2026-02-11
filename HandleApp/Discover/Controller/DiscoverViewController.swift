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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        trendingTopics = ideasResponse.trendingTopics
        publishReadyPosts = ideasResponse.publishReadyPosts
        
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
    
//    func loadSupabaseData() async {
//        print("Starting Supabase Fetch ")
//        
//        do {
//            
//            let fetchedData = try await SupabaseManager.shared.loadPostsIdeas()
//            
//            await MainActor.run {
//                print("Data Received. Updating UI...")
//                
//                self.ideasResponse = fetchedData
//                
//                self.trendingTopics = fetchedData.trendingTopics
//                self.topicDetails = fetchedData.topicDetails
//                
//                self.publishReadyPosts = fetchedData.publishReadyPosts
//                
//                self.collectionView.reloadData()
//            }
//            
//        } catch {
//            print("Error loading data: \(error.localizedDescription)")
//        }
//    }
    
    // In DiscoverViewController.swift

    func loadSupabaseData() async {
        print("Starting Industry-Specific Data Load...")
        
        do {
            // 1. Identify User & Fetch Profile Context (Required for Section 2)
            guard let user = try? await SupabaseManager.shared.client.auth.session.user,
                  let userProfile = await SupabaseManager.shared.fetchUserProfile() else {
                print("No user profile found. Falling back to generic load.")
                // Fallback: Maintain your original global fetch if profile isn't ready
                let fetchedData = try await SupabaseManager.shared.loadPostsIdeas()
                updateUI(with: fetchedData)
                return
            }

            // 2. Fetch User's Industry from Onboarding Responses (Step 2)
            let onboardingResponse: [String: [String]] = try await SupabaseManager.shared.client
                .from("onboarding_responses")
                .select("selection_tags")
                .eq("user_id", value: user.id)
                .eq("step_index", value: 2)
                .single()
                .execute()
                .value

            let userNiche = onboardingResponse["selection_tags"]?.first ?? "Technology & Software"
            print("Industry Found: \(userNiche). Filtering trends...")

            // 3. Fetch ONLY matching Trending Topics (Personalized Section 1)
            let fetchedTrends: [TrendingTopic] = try await SupabaseManager.shared.client
                .from("trending_topics")
                .select("*")
                .eq("category", value: userNiche)
                .order("created_at", ascending: false)
                .limit(10)
                .execute()
                .value

            // 4. Update UI for Trending Section (Section 1)
            await MainActor.run {
                self.trendingTopics = fetchedTrends
                // We use reloadData here initially to sync the new trend list
                self.collectionView.reloadData()
            }

            // 5. Section 2: Trigger AI Post Generation based on the Newest Trend
            let topTrend = fetchedTrends.first
            let topTrendName = topTrend?.topicName ?? "Digital Marketing Trends"
            let topTrendDesc = topTrend?.shortDescription ?? "Latest industry shifts"
            let combinedTrendText = "\(topTrendName): \(topTrendDesc)"
            
            print("Generative AI: Starting generation for trend: \(topTrendName)")

            let generatedPosts = try await OnDevicePostEngine.shared.generatePublishReadyPosts(
                trendText: combinedTrendText,
                context: userProfile
            )

            // 6. Update Section 2 (Publish Ready)
            await MainActor.run {
                print("AI Generation Complete. Reloading Section 2.")
                self.publishReadyPosts = generatedPosts
                self.collectionView.reloadSections(IndexSet(integer: 2))
            }
            
        } catch {
            print("Personalized Fetch failed, falling back to original logic: \(error.localizedDescription)")
            // Fallback: Run your original global fetch if anything in the personalization fails
            if let fetchedData = try? await SupabaseManager.shared.loadPostsIdeas() {
                updateUI(with: fetchedData)
            }
        }
    }

    // Helper to prevent code duplication in fallbacks
    @MainActor
    private func updateUI(with data: DiscoverIdeaResponse) {
        self.ideasResponse = data
        self.trendingTopics = data.trendingTopics
        self.collectionView.reloadData()
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
                
                cell.didTapButtonAction = { [weak self] in
                    self?.navigateToChat()
                }
                
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
    
    func navigateToChat() {
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
  
        if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? UserIdeaViewController {
            self.navigationController?.pushViewController(chatVC, animated: true)
        } else {
            print("Error: Could not find ChatViewController")
        }
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
         
            if indexPath.section == 1 {
                let selectedTopic = trendingTopics[indexPath.row]
                print("Selected Topic: \(selectedTopic.topicName)")
                
                let storyboard = UIStoryboard(name: "Discover", bundle: nil)
                if let destVC = storyboard.instantiateViewController(withIdentifier: "TopicIdeasVC") as? TopicIdeaViewController {
                    
                    destVC.topic = selectedTopic
                    destVC.pageTitle = selectedTopic.topicName
                    
                    navigationController?.pushViewController(destVC, animated: true)
                }
            }
            
            
            if indexPath.section == 2 {
                let selectedPost = publishReadyPosts[indexPath.row]
    
                        self.showLoading()
                        
                        Task {
                            do {
                                guard let profile = await SupabaseManager.shared.fetchUserProfile() else {
                                    await MainActor.run { self.hideLoading() }
                                    return
                                }
  
                                let finalDraft = try await OnDevicePostEngine.shared.refinePostForEditor(
                                    post: selectedPost,
                                    context: profile
                                )
                                
                                await MainActor.run {
                                    self.hideLoading()

                                    self.performSegue(withIdentifier: "ShowEditorSegue", sender: finalDraft)
                                }
                            } catch {
                                await MainActor.run {
                                    self.hideLoading()
                                    print("Error refining post: \(error)")
                                }
                            }
                        }
                
            }
        }
    
    func showLoading() {
        let alert = UIAlertController(title: nil, message: "Generating with AI...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }

    func hideLoading() {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowEditorSegue",
           let editorVC = segue.destination as? EditorSuiteViewController,
           let data = sender as? EditorDraftData {
            
            editorVC.draft = data
        }
    }
        
    }

