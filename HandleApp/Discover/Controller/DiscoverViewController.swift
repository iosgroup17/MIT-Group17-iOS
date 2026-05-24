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
    var publishReadyPosts: [PublishReadyPost] = []

    var isGeneratingPosts: Bool = false

    var savedCount: Int = 0
    var scheduledCount: Int = 0

    // Whether the "Complete your profile" card (section 0) is currently visible.
    var showNudge: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        publishReadyPosts = ideasResponse.publishReadyPosts

        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(
            UINib(nibName: "CurateAICollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "CurateAICollectionViewCell"
        )

        collectionView.register(
            UINib(nibName: "PostsCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "PostsCollectionViewCell"
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

        collectionView.register(
                    UICollectionViewCell.self,
                    forCellWithReuseIdentifier: "LoadingCell"
        )

        collectionView.register(
            ProfileNudgeCell.self,
            forCellWithReuseIdentifier: ProfileNudgeCell.reuseID
        )

        collectionView.setCollectionViewLayout(generateLayout(), animated: true)

        refreshProfileNudge()

        Task {
                await loadSupabaseData()
            }

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleProfileChange),
                name: .userProfileDidChange,
                object: nil
            )

        NotificationCenter.default.addObserver(self, selector: #selector(refreshCounts), name: NSNotification.Name("PostStatusChanged"), object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshCounts()
        refreshProfileNudge()
    }

    @objc func handleProfileChange() {
        Task {
            await loadSupabaseData()
        }
        refreshProfileNudge()
    }

    // MARK: - Profile completion card

    /// Pulls the latest onboarding answers, then recomputes whether the card shows.
    func refreshProfileNudge() {
        Task {
            let responses = await SupabaseManager.shared.fetchUserOnboardingData()
            await MainActor.run {
                OnboardingDataStore.shared.syncWithRemoteData(responses)
                self.recomputeNudge()
            }
        }
    }

    /// Recompute visibility from the current store state and refresh section 0.
    func recomputeNudge() {
        let store = OnboardingDataStore.shared
        showNudge = !ProfileChecklist.isComplete && !store.profileNudgeDismissedThisSession
        collectionView.reloadSections(IndexSet(integer: 0))
    }

    func dismissNudge() {
        OnboardingDataStore.shared.profileNudgeDismissedThisSession = true
        recomputeNudge()
    }

    func presentProfileHub() {
        let hub = ProfileCompletionHubViewController()
        hub.onChange = { [weak self] in
            self?.recomputeNudge()
        }
        let nav = UINavigationController(rootViewController: hub)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func refreshCounts() {
        Task {
            let sCount = try? await SupabaseManager.shared.fetchPostCount(for: .saved)
            let schCount = try? await SupabaseManager.shared.fetchPostCount(for: .scheduled)

            await MainActor.run {
                self.savedCount = sCount ?? 0
                self.scheduledCount = schCount ?? 0
                self.collectionView.reloadSections(IndexSet(integer: 2))
            }
        }
    }

    func loadSupabaseData() async {

            do {
                refreshCounts()

                var userProfile: UserProfile

                if let profile = await SupabaseManager.shared.fetchUserProfile() {
                    userProfile = profile
                } else {

                    userProfile = UserProfile(
                        professionalIdentity: ["Content Creator"],
                        currentFocus: ["Trends"],
                        industry: ["General"],
                        primaryGoals: ["General Audience"],
                        contentFormats: ["Growth"],
                        platforms: [" engaging"],
                        targetAudience: ["LinkedIn"],
                        acceptedRules: []
                    )
                }

                await MainActor.run {
                    self.isGeneratingPosts = true
                    self.collectionView.reloadSections(IndexSet(integer: 3))
                }

                let generatedPosts = try await OnDevicePostEngine.shared.generatePublishReadyPosts(
                    context: userProfile
                )

                await MainActor.run {
                    self.publishReadyPosts = generatedPosts
                    self.isGeneratingPosts = false
                    self.collectionView.reloadSections(IndexSet(integer: 3))
                }

            } catch {
                await MainActor.run {
                    self.isGeneratingPosts = false
                    self.collectionView.reloadSections(IndexSet(integer: 3))
                }
            }
        }

    // Helper to prevent code duplication in fallbacks
    @MainActor
    private func updateUI(with data: DiscoverIdeaResponse) {
        self.ideasResponse = data
        self.collectionView.reloadData()
    }

    func generateLayout() -> UICollectionViewLayout {

        return UICollectionViewCompositionalLayout { section, _ -> NSCollectionLayoutSection? in

            // Section 0: profile-completion card. The cell carries its own margins,
            // so zero insets here let the section collapse cleanly when it has 0 items.
            if section == 0 {

                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(120)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: itemSize,
                    subitems: [item]
                )

                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.contentInsets = .zero
                return sectionLayout
            }

            if section == 1 {

                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(80)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(85)
                )

                // Use .horizontal for horizontal flow ( L - R )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                let sectionLayout = NSCollectionLayoutSection(group: group)

                sectionLayout.contentInsets = NSDirectionalEdgeInsets(
                    top: 10, leading: 16, bottom: 20, trailing: 16
                )

                return sectionLayout

            }

            if section == 2 {

                let itemSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(0.5),
                        heightDimension: .absolute(70)
                    )

                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(75)
                )

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                group.interItemSpacing = .fixed(12)

                let sectionLayout = NSCollectionLayoutSection(group: group)
                sectionLayout.interGroupSpacing = 16

                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(44)
                )

                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )

                header.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: -8, bottom: 0, trailing: 0)

                sectionLayout.boundarySupplementaryItems = [header]

                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 20, trailing: 16)

                return sectionLayout
            }

            if section == 3 {

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
                sectionLayout.interGroupSpacing = 20

                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(44)
                )

                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )

                header.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: -8, bottom: 4, trailing: 0)

                sectionLayout.boundarySupplementaryItems = [header]

                sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 20, trailing: 16)

                return sectionLayout
            }
            return nil
        }
    }
}

extension DiscoverViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return showNudge ? 1 : 0 }
        if section == 1 { return 1 }
        if section == 2 { return 2 }
        if section == 3 { return isGeneratingPosts ? 1 : publishReadyPosts.count }

        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProfileNudgeCell.reuseID,
                for: indexPath
            ) as! ProfileNudgeCell

            cell.configure(completed: ProfileChecklist.completedCount, total: ProfileChecklist.totalCount)
            cell.dismissAction = { [weak self] in
                self?.dismissNudge()
            }

            return cell
        }

        if indexPath.section == 1 {

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "CurateAICollectionViewCell",
                for: indexPath
            ) as! CurateAICollectionViewCell

            cell.didTapButtonAction = { [weak self] in
                self?.navigateToChat()
            }

            return cell

        }

        if indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "PostsCollectionViewCell",
                for: indexPath
            ) as! PostsCollectionViewCell

            // Logic: Item 0 is Saved, Item 1 is Scheduled
            if indexPath.row == 0 {
                cell.configure(type: "Saved", count: savedCount)
            } else {
                cell.configure(type: "Scheduled", count: scheduledCount)
            }

            // Styling the cell to look like a "Pill"
            cell.layer.cornerRadius = 12
            cell.layer.backgroundColor = UIColor.systemGray6.cgColor

            return cell
        }

        if indexPath.section == 3 {
            if isGeneratingPosts {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LoadingCell", for: indexPath)

                // clear out old views when cells are reused
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }

                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.translatesAutoresizingMaskIntoConstraints = false
                spinner.startAnimating()

                cell.contentView.addSubview(spinner)
                NSLayoutConstraint.activate([
                    spinner.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                    spinner.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
                ])

                return cell
            }

            let post = publishReadyPosts[indexPath.row]

            if let img = post.postImage, !img.isEmpty {
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

    func navigateToChat() {
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)

        if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? UserIdeaViewController {
            self.navigationController?.pushViewController(chatVC, animated: true)
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
        if indexPath.section == 2 {
            header.titleLabel.text = "Your Content Summary"
        }
        if indexPath.section == 3 {
            header.titleLabel.text = "Suggested For You"
        }

        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if indexPath.section == 0 {
            presentProfileHub()
        }

        if indexPath.section == 1 {
            let storyboard = UIStoryboard(name: "Discover", bundle: nil)
            if let destVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? UserIdeaViewController {
                navigationController?.pushViewController(destVC, animated: true)
            }
        }

        if indexPath.section == 2 {
            if indexPath.row == 0 {
                let storyboard = UIStoryboard(name: "Posts", bundle: nil)
                if let destinationVC = storyboard.instantiateViewController(withIdentifier: "SavedPostsViewControllerID") as? SavedPostsTableViewController {
                    self.navigationController?.pushViewController(destinationVC, animated: true)
                } else {
                }
            } else {
                let storyboard = UIStoryboard(name: "Posts", bundle: nil)
                if let destinationVC = storyboard.instantiateViewController(withIdentifier: "ScheduledPostsViewControllerID") as? ScheduledPostsTableViewController {
                    self.navigationController?.pushViewController(destinationVC, animated: true)
                } else {
                }
            }
        }

        if indexPath.section == 3 {
            let selectedPost = publishReadyPosts[indexPath.row]

            self.showRefinementLoading()

            Task {
                do {
                    guard let profile = await SupabaseManager.shared.fetchUserProfile() else {
                        await MainActor.run { self.hideRefinementLoading() }
                        return
                    }

                    let finalDraft = try await OnDevicePostEngine.shared.refinePostForEditor(
                        post: selectedPost,
                        context: profile
                    )

                    await MainActor.run {
                        self.hideRefinementLoading()

                        self.performSegue(withIdentifier: "ShowEditorSegue", sender: finalDraft)
                    }
                } catch {
                    await MainActor.run {
                        self.hideRefinementLoading()
                    }
                }
            }
        }
    }

    func showRefinementLoading() {
        let alert = UIAlertController(title: nil, message: "Preparing Editor...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 20, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }

    func hideRefinementLoading() {
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
