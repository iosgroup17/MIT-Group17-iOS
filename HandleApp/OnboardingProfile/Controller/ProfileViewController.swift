import UIKit

class ProfileViewController: UIViewController {
    
    // 1. The Image at the top
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var completionProgress: UIProgressView!
    
    // 2. The Card Backgrounds (To apply shadow/corners)
    @IBOutlet weak var accountCardView: UIView!
    @IBOutlet weak var detailsCardView: UIView!
    @IBOutlet weak var socialCardView: UIView!
    @IBOutlet weak var progressCardView: UIView!
    
    // 3. The Stack Views INSIDE the cards (Where we inject rows)
    @IBOutlet weak var accountStack: UIStackView!
    @IBOutlet weak var detailsStack: UIStackView!
    @IBOutlet weak var socialStack: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data every time we appear (in case user returns from editing)
        loadData()
    }
    
    func setupUI() {
        // Round Image
        profileImageView.image = UIImage(named: "Avatar")
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.white.cgColor
        
        let cards = [accountCardView, detailsCardView, socialCardView, progressCardView]
        for card in cards {
            // Safe check for optionals
            if let c = card {
                c.backgroundColor = .white
                c.layer.cornerRadius = 16 // Smooth curve
                
                // Subtle Drop Shadow
                c.layer.shadowColor = UIColor.black.cgColor
                c.layer.shadowOpacity = 0.06 // Very light and clean
                c.layer.shadowOffset = CGSize(width: 0, height: 4)
                c.layer.shadowRadius = 8
            }
        }
        // Style the Cards
        styleCard(accountCardView)
        styleCard(detailsCardView)
        styleCard(socialCardView)
    }
    
    func styleCard(_ view: UIView) {
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        // Shadow Effect
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
    }
    
    // MARK: - Data Loading (The Engine)
    func loadData() {
        let store = OnboardingDataStore.shared
        
        // 1. Update Progress
        completionProgress.setProgress(store.completionPercentage, animated: false)
        
        // 2. Clear Old Rows (Critical: Prevents duplicates when reloading)
        accountStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        detailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        socialStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // -----------------------------
        // SECTION 1: ACCOUNT (Text Input)
        // -----------------------------
        
        // Display Name Row
        addRow(to: accountStack, title: "Display Name", value: store.displayName ?? "") {
            self.showTextInput(title: "Edit Name", currentValue: store.displayName) { text in
                store.displayName = text // Save to Store
                self.loadData()          // Refresh UI
            }
        }
        
        // Bio Row
        addRow(to: accountStack, title: "Short Bio", value: store.shortBio ?? "") {
            self.showTextInput(title: "Edit Bio", currentValue: store.shortBio) { text in
                store.shortBio = text
                self.loadData()
            }
        }
        
        // -----------------------------
        // SECTION 2: DETAILS (Quiz Navigation)
        // -----------------------------
        
        // Role (Step 0)
        // Note: Quiz answers are saved as [String], so we take the .first item
        let role = (store.userAnswers[0] as? [String])?.first ?? ""
        addRow(to: detailsStack, title: "Role", value: role) {
            self.openEditor(forStep: 0)
        }
        
        // Industry (Step 2)
        let industry = (store.userAnswers[2] as? [String])?.first ?? ""
        addRow(to: detailsStack, title: "Industry", value: industry) {
            self.openEditor(forStep: 2)
        }
        
        // Goals (Step 1 - Multi Select)
        let goals = (store.userAnswers[1] as? [String])?.joined(separator: ", ") ?? ""
        addRow(to: detailsStack, title: "Goals", value: goals) {
            self.openEditor(forStep: 1)
        }
        
        let formats = (store.userAnswers[3] as? [String])?.joined(separator: ", ") ?? ""
        
        // Add the row
        addRow(to: detailsStack, title: "Formats", value: formats) {
            // Open the specific question (Index 3)
            self.openEditor(forStep: 3)
        }
        
        // 3. TARGET AUDIENCE (Assuming Step 3)
        // Check your OnboardingDataStore to confirm if Audience is index 3 or 4
        let audienceList = store.userAnswers[5] as? [String]
        let audience = audienceList?.joined(separator: ", ") ?? "General"
        
        addRow(to: detailsStack, title: "Audience", value: audience) {
            self.openEditor(forStep: 5) // Make sure this index matches your "Audience" step!
        }
        
        // 4. TONE (Assuming Step 5 - Sliders)
        // Tone is saved as [String: Float], e.g. ["Formal": 0.8]
        if let toneArray = store.userAnswers[4] as? [String] {
            let toneString = toneArray.joined(separator: ", ")
            
            addRow(to: detailsStack, title: "Tone", value: toneString) {
                self.openEditor(forStep: 4)
            }
        } else {
            addRow(to: detailsStack, title: "Tone", value: "Select") {
                self.openEditor(forStep: 4)
            }
        }
        
        // -----------------------------
        // SECTION 3: SOCIALS (Toggles)
        // -----------------------------
        
        for (platform, isConnected) in store.socialStatus {
            addRow(to: socialStack, title: platform, value: "", isToggle: true, isConnected: isConnected) {
                // This block runs when toggle is switched (handled inside ProfileRow technically)
            }
            
            // Note: Since the Row handles the toggle visual, we need to sync data
            // We usually handle toggle logic inside the row's configuration,
            // but for simplicity, we rely on the row visual state.
            // *Ideally, update your ProfileRow to take a callback for the switch.*
        }
        
        hideLastSeparator(in: socialStack)
        hideLastSeparator(in: detailsStack)
        hideLastSeparator(in: accountStack)
    }
    
    func addRow(to stack: UIStackView, title: String, value: String, isToggle: Bool = false, isConnected: Bool = false, action: @escaping () -> Void) {
        
        // 1. Create the Row
        let row = ProfileRow()
        // Note: Since we set File's Owner, init() automatically loads the XIB!
        
        // 2. Configure Data
        row.configure(title: title, value: value, isToggle: isToggle, isConnected: isConnected)
        
        // 3. Assign Tap Action
        row.tapAction = action
        
        // 4. Handle Switch Toggle (If it's a social row)
        if isToggle {
            // We intercept the switch tap here to update our model
            // You might need to add a callback to your ProfileRow class for the switch specifically
            // For now, let's assume tapping the row triggers the action
        }
        
        // 5. Layout Constraints
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // 6. Add to Stack
        stack.addArrangedSubview(row)
    }
    
    
    func showTextInput(title: String, currentValue: String?, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = currentValue
            textField.placeholder = "Enter here..."
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                completion(text)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func navigateToQuiz(stepIndex: Int) {
        // 1. Instantiate the Parent Onboarding Controller
        // Ensure your OnboardingViewController has a Storyboard ID: "OnboardingParentVC"
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "OnboardingParentVC") as? OnboardingViewController else {
            print("Error: Could not find OnboardingViewController")
            return
        }
        
        // 2. We need a way to tell it "Start at Step X"
        // You might need to change 'private var currentStepIndex' to 'public' in OnboardingViewController
        vc.currentStepIndex = stepIndex
        
        // 3. Present it
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    func hideLastSeparator(in stack: UIStackView) {
        // Find the last row in the stack and hide its line
        if let lastRow = stack.arrangedSubviews.last as? ProfileRow {
            lastRow.separatorLine.isHidden = true
        }
    }
    
    func openEditor(forStep stepIndex: Int) {
        
        // 1. Find the Onboarding Storyboard
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        
        // 2. Create the Onboarding View Controller
        // Make sure the Storyboard ID is set to "OnboardingParentVC" in Main.storyboard
        guard let editorVC = storyboard.instantiateViewController(withIdentifier: "OnboardingParentVC") as? OnboardingViewController else {
            print("Error: Could not find OnboardingViewController. Check Storyboard ID.")
            return
        }
        
        // 3. Configure it for "Edit Mode"
        // (You must have added 'var isEditMode = false' to OnboardingViewController previously)
        editorVC.currentStepIndex = stepIndex
        editorVC.isEditMode = true
        
        // 4. Present it nicely as a sheet
        editorVC.onDismiss = { [weak self] in
            self?.loadData()
        }
        
        // 5. Present it nicely as a sheet
        editorVC.modalPresentationStyle = .pageSheet
        if let sheet = editorVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()] // Allows it to slide up half-way
            sheet.prefersGrabberVisible = true
        }
        
        present(editorVC, animated: true)
    }
}
