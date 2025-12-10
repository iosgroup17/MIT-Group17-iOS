import UIKit

class ListSelectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate{
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var items: [OnboardingOption] = []
    var layoutType: OnboardingLayoutType = .singleSelectChips
    var stepIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        switch layoutType {
        case .multiSelectCards:
            collectionView.allowsMultipleSelection = true
        default:
            collectionView.allowsMultipleSelection = false
        }
        
        setupLayout()
        
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
    
    func setupLayout() {
        if layoutType == .singleSelectChips {
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .absolute(200))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 40, bottom: 15, trailing: 40)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(200))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
            
            let layout = UICollectionViewCompositionalLayout(section: section)
            collectionView.setCollectionViewLayout(layout, animated: false)
            
        } else {
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.showsSeparators = false
            config.backgroundColor = .clear
            let layout = UICollectionViewCompositionalLayout.list(using: config)
            collectionView.setCollectionViewLayout(layout, animated: false)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellID: String
        if layoutType == .singleSelectChips {
            cellID = "BigCardCell"
        } else {
            cellID = "SelectionCell"
        }
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as? SelectionCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: items[indexPath.row])
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? SelectionCell {
            cell.isSelected = true
        }
        
        // Run your save function
        saveSelection()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        saveSelection()
    }
    
    func saveSelection() {
        
        // 1. Get all selected items (Works for Single AND Multi select)
        // If nothing is selected, we default to an empty list []
        let selectedIndexPaths = collectionView.indexPathsForSelectedItems ?? []
        
        // 2. Convert IndexPaths to Strings
        // Example Single: ["Founder"]
        // Example Multi: ["Revenue", "Networking"]
        let selectedTitles: [String] = selectedIndexPaths.map { indexPath in
            return items[indexPath.row].title
        }
        
        print("Step \(stepIndex) Saved: \(selectedTitles)")
        
        // 3. Save to DataStore (Always as an Array)
        OnboardingDataStore.shared.saveAnswer(stepIndex: stepIndex, value: selectedTitles)
    }
    
    
}
