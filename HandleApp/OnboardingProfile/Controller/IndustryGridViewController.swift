import UIKit

class IndustryGridViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var items: [OnboardingOption] = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var stepIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = false
        
        setupGridLayout()
        
        // We cast strictly to [String] because we know we saved it as an array
        if let savedArray = OnboardingDataStore.shared.userAnswers[stepIndex] as? [String] {
            
            // Loop through our items
            for (index, item) in items.enumerated() {
                
                // Check if the array contains this title
                if savedArray.contains(item.title) {
                    let indexPath = IndexPath(row: index, section: 0)
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }
            }
        }
    }
    
    func setupGridLayout() {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.33), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.33))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        group.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCell", for: indexPath) as? GridCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = items[indexPath.row]
        print("Step 2: Industry - \(selectedItem.title)")
        
        // WRAP IT IN BRACKETS [] TO MAKE IT AN ARRAY
        OnboardingDataStore.shared.saveAnswer(stepIndex: stepIndex, value: [selectedItem.title])
    }
}
