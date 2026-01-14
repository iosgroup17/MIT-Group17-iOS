import UIKit

class ProfileViewController: UIViewController {
    
    //image at the top
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var completionProgress: UIProgressView!
    
    //card backgrounds
    @IBOutlet weak var accountCardView: UIView!
    @IBOutlet weak var detailsCardView: UIView!
    @IBOutlet weak var socialCardView: UIView!
    @IBOutlet weak var progressCardView: UIView!
    
    //The Stack Views INSIDE the cards (Where we inject rows)
    @IBOutlet weak var accountStack: UIStackView!
    @IBOutlet weak var detailsStack: UIStackView!
    @IBOutlet weak var socialStack: UIStackView!
    
    let store = OnboardingDataStore.shared
    
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
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.white.cgColor
        
        let cards = [accountCardView, detailsCardView, socialCardView, progressCardView]
        for card in cards {
            if let c = card {
                c.backgroundColor = .white
                c.layer.cornerRadius = 16
                
                // Subtle Drop Shadow
                c.layer.shadowColor = UIColor.black.cgColor
                c.layer.shadowOpacity = 0.06 
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
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
    }
    
    func loadData() {
        let store = OnboardingDataStore.shared
        
        //Update Progress
        completionProgress.setProgress(store.completionPercentage, animated: false)
        
        //Clear Old Rows
        accountStack.arrangedSubviews.forEach { subview in
            subview.removeFromSuperview()
        }

        detailsStack.arrangedSubviews.forEach { subview in
            subview.removeFromSuperview()
        }

        socialStack.arrangedSubviews.forEach { subview in
            subview.removeFromSuperview()
        }

        // name
        addRow(to: accountStack, title: "Display Name", value: store.displayName ?? "", showIcon: false) {
            self.showTextInput(title: "Edit Name", currentValue: store.displayName) { text in
                store.displayName = text
                self.loadData()          
            }
        }
        
        // bio
        addRow(to: accountStack, title: "Short Bio", value: store.shortBio ?? "", showIcon: false) {
            self.showTextInput(title: "Edit Bio", currentValue: store.shortBio) { text in
                store.shortBio = text
                self.loadData()
            }
        }
      
        // role
        let role = (store.userAnswers[0] as? [String])?.first ?? ""
        addRow(to: detailsStack, title: "Role", value: role) {
            self.openEditor(forStep: 0)
        }
        
        // industry
        let goals = (store.userAnswers[1] as? [String])?.joined(separator: ", ") ?? ""
        addRow(to: detailsStack, title: "Industry", value: goals) {
            self.openEditor(forStep: 1)
        }
        
        // goals
        let industry = (store.userAnswers[2] as? [String])?.first ?? ""
        addRow(to: detailsStack, title: "Goals", value: industry) {
            self.openEditor(forStep: 2)
        }
        
        // content formats
        let formats = (store.userAnswers[3] as? [String])?.joined(separator: ", ") ?? ""
        addRow(to: detailsStack, title: "Formats", value: formats) {
            self.openEditor(forStep: 3)
        }
        
        // target audience
        let audienceList = store.userAnswers[5] as? [String]
        let audience = audienceList?.joined(separator: ", ") ?? "General"
        
        addRow(to: detailsStack, title: "Audience", value: audience) {
            self.openEditor(forStep: 5)
        }
        
     
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
     
        setupSocialRows()
        
        hideLastSeparator(in: socialStack)
        hideLastSeparator(in: detailsStack)
        hideLastSeparator(in: accountStack)
    }
    
    func addRow(to stack: UIStackView, title: String, value: String, isToggle: Bool = false, isConnected: Bool = false, showIcon: Bool = true, action: @escaping () -> Void) {
        
        // create row
        let row = ProfileRow()
        
        // configure row with data
        row.configure(title: title, value: value, isToggle: isToggle, isConnected: isConnected, showIcon: showIcon)
        
        // assign action
        row.tapAction = action
        
        // set height constraint
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // add to stack
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
    
    func hideLastSeparator(in stack: UIStackView) {
        if let lastRow = stack.arrangedSubviews.last as? ProfileRow {
            lastRow.separatorLine.isHidden = true
        }
    }
    
    func openEditor(forStep stepIndex: Int) {
        
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        
        // instantiate onboardingVC here
        guard let editorVC = storyboard.instantiateViewController(withIdentifier: "OnboardingParentVC") as? OnboardingViewController else {
            print("Error: Could not find OnboardingViewController. Check Storyboard ID.")
            return
        }
        
        // configure for editing 
        editorVC.currentStepIndex = stepIndex
        editorVC.isEditMode = true
        
        // present as sheet
        editorVC.onDismiss = { [weak self] in
            self?.loadData()
        }
        
        editorVC.modalPresentationStyle = .pageSheet
        if let sheet = editorVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(editorVC, animated: true)
    }

    func setupSocialRows() {
        socialStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (platform, isConnected) in store.socialStatus {
            
            addRow(to: socialStack, title: platform, value: "", isToggle: true, isConnected: isConnected) { [weak self] in
                
                let currentStatus = self?.store.socialStatus[platform] ?? false
                
                if currentStatus == true {
                    self?.store.socialStatus[platform] = false
                    print("Disconnected")
                    self?.setupSocialRows()
                } else {
                    self?.openConnectionScreen(platformName: platform)
                }
            }
        }
    }
    
    func openConnectionScreen(platformName: String) {
        let storyboard = UIStoryboard(name: "Analytics", bundle: nil)
        
        guard let connectionVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            return
        }
        
        connectionVC.onCompletion = { [weak self] isSuccess in
            guard let self = self else { return }
            
            if isSuccess {
                print("Success! Connecting \(platformName)")
                store.socialStatus[platformName] = true
                
            } else {
                print("User skipped. Reverting switch.")
            }

            self.reloadSocialSection()
        }
        
        connectionVC.modalPresentationStyle = .pageSheet
        if let sheet = connectionVC.sheetPresentationController {
            sheet.detents = [.large()]
        }
        present(connectionVC, animated: true)
    }

    func reloadSocialSection() {
        socialStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (platform, isConnected) in store.socialStatus {
                
                addRow(to: socialStack, title: platform, value: "", isToggle: true, isConnected: isConnected) { [weak self] in
                    
                    let currentStatus = self?.store.socialStatus[platform] ?? false
                    
                    if currentStatus == true {
                        self?.store.socialStatus[platform] = false
                        print("Disconnected")
                        self?.setupSocialRows()
                    } else {
                        self?.openConnectionScreen(platformName: platform)
                    }
                }
            }
        }
}
