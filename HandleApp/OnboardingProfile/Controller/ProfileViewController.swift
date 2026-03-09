import UIKit
import Supabase

class ProfileViewController: UIViewController {
    
    //image at the top
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var completionProgress: UIProgressView!
    
    //card backgrounds
    @IBOutlet weak var accountCardView: UIView!
    @IBOutlet weak var detailsCardView: UIView!
    @IBOutlet weak var socialCardView: UIView!
    @IBOutlet weak var progressCardView: UIView!
    
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
        
        completionProgress.setProgress(store.completionPercentage, animated: false)
        
        [accountStack, detailsStack, socialStack].forEach { stack in
            stack?.arrangedSubviews.forEach { $0.removeFromSuperview() }
        }

        
        addRow(to: accountStack, title: "Display Name", value: store.displayName ?? "", showIcon: false) {
            self.showTextInput(title: "Edit Name", currentValue: store.displayName) { text in
                store.displayName = text
                self.loadData()
            }
        }
        
        addRow(to: accountStack, title: "Short Bio", value: store.shortBio ?? "", showIcon: false) {
            self.showTextInput(title: "Edit Bio", currentValue: store.shortBio) { text in
                store.shortBio = text
                self.loadData()
            }
        }
      
        let role = (store.userAnswers[0] as? [String])?.first ?? "Select"
        addRow(to: detailsStack, title: "Role", value: role) {
            self.openEditor(forStep: 0)
        }
        
        let workFocus = (store.userAnswers[1] as? [String])?.first ?? "Select"
        addRow(to: detailsStack, title: "Focus", value: workFocus) {
            self.openEditor(forStep: 1)
        }
        
        let industry = (store.userAnswers[2] as? [String])?.first ?? "Select"
        addRow(to: detailsStack, title: "Industry", value: industry) {
            self.openEditor(forStep: 2)
        }
        
        let goals = (store.userAnswers[3] as? [String])?.first ?? "Select"
        addRow(to: detailsStack, title: "Goals", value: goals) {
            self.openEditor(forStep: 3)
        }
        
        let formats = (store.userAnswers[4] as? [String])?.joined(separator: ", ") ?? "Select"
        addRow(to: detailsStack, title: "Formats", value: formats) {
            self.openEditor(forStep: 4)
        }
        
        let platforms = (store.userAnswers[5] as? [String])?.joined(separator: ", ") ?? "Select"
        addRow(to: detailsStack, title: "Platforms", value: platforms) {
            self.openEditor(forStep: 5)
        }
        
        let audience = (store.userAnswers[6] as? [String])?.joined(separator: ", ") ?? "General"
        addRow(to: detailsStack, title: "Audience", value: audience) {
            self.openEditor(forStep: 6)
        }
        
        let logoutRow = ProfileRow()
        let logoutIcon = UIImage(systemName: "rectangle.portrait.and.arrow.right")
        addRow(to: socialStack,
               title: "Logout",
               value: "",
               titleColor: .systemRed,
               iconImage: logoutIcon) { [weak self] in
            self?.showLogoutConfirmation()
        }

        hideLastSeparator(in: socialStack)
        hideLastSeparator(in: detailsStack)
        hideLastSeparator(in: accountStack)
    }
    
    func addRow(to stack: UIStackView, title: String, value: String, showIcon: Bool = true, titleColor: UIColor = .label, iconImage: UIImage? = nil, action: @escaping () -> Void) {
        let row = ProfileRow()
        row.configure(title: title, value: value, showIcon: showIcon, titleColor: titleColor, iconImage: iconImage)
        row.tapAction = action
        
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 50).isActive = true
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
    
    func showLogoutConfirmation() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out of your account?", preferredStyle: .actionSheet)
        
        let logoutAction = UIAlertAction(title: "Log Out", style: .destructive) { _ in
            self.handleLogout()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(logoutAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

    func handleLogout() {
        Task {
            try? await SupabaseManager.shared.client.auth.signOut()
            OnboardingDataStore.shared.reset()

            DispatchQueue.main.async {
                if let window = self.view.window,
                   let _ = window.windowScene?.delegate as? SceneDelegate {
                    
                    let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginAuthVC")
                    
                    window.rootViewController = loginVC
                    
                    UIView.transition(with: window,
                                    duration: 0.3,
                                    options: .transitionCrossDissolve,
                                    animations: nil,
                                    completion: nil)
                }
            }
        }
    }
}
