import UIKit
import Supabase

class OnboardingViewController: UIViewController {
    
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var descLabel: UILabel!
    
    public var currentStepIndex: Int = 0
    var currentChildViewController: UIViewController?
    var isEditMode: Bool = false
    var onDismiss: (() -> Void)?
    let client = SupabaseManager.shared.client
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIForStep(index: currentStepIndex)
        
        if isEditMode {
            setupForEditing()
        }
    }
    
    func setupForEditing() {
        // hide quiz ui
        progressView.isHidden = true
        stepLabel.isHidden = true
        skipButton.isHidden = true
        
        nextButton.setTitle("Save Update", for: .normal)
        
        // hide back button
        backButton.isHidden = true
        
        // change next button to save
        nextButton.setTitle("Save", for: .normal)
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        Task { @MainActor in
            //check if current step has an answer
            let hasAnswer = OnboardingDataStore.shared.userAnswers[currentStepIndex] != nil
            
            //required steps
            if !hasAnswer {
                showAlert(message: "This step is required. Please select an option.")
                return
            }
            
            let rawAnswer = OnboardingDataStore.shared.userAnswers[currentStepIndex]
            let selectedOptions: [String]
            
            if let singleValue = rawAnswer as? String {
                selectedOptions = [singleValue]
            } else if let multiValue = rawAnswer as? [String] {
                selectedOptions = multiValue
            } else {
                selectedOptions = []
            }
            
            //bg task to update supabase
            Task {
                print("Syncing Step \(currentStepIndex) to Supabase...")
                
                // test id call
                await SupabaseManager.shared.savePreference(
                    stepIndex: currentStepIndex,
                    selections: selectedOptions
                )
                
                DispatchQueue.main.async {
                    // NEW: Broadcast that the profile has changed!
                    NotificationCenter.default.post(name: .userProfileDidChange, object: nil)
                    
                    if self.isEditMode {
                        self.onDismiss?()
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        self.goToNextStep()
                    }
                }
            }
        }
    }
    
    @IBAction func skipButtonTapped(_ sender: Any) {
        goToNextStep()
    }
    
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        if currentStepIndex > 0{
            currentStepIndex -= 1
            updateUIForStep(index: currentStepIndex)
        }
    }
    
    func updateUIForStep(index: Int) {
        guard let stepData = OnboardingDataStore.shared.getStep(at: index) else { return }
        let totalOnboardingSteps = 3 // We only want 3 steps for the initial quiz
        
        questionLabel.text = stepData.title
        stepLabel.text = "Step \(index + 1) of \(totalOnboardingSteps)"
        progressView.setProgress(Float(index + 1) / Float(totalOnboardingSteps), animated: true)
        
        if let desc = stepData.description, !desc.isEmpty {
            descLabel.text = desc
            descLabel.isHidden = false
        } else {
            descLabel.text = ""
            descLabel.isHidden = true
        }
        
        if index == 0 {
            backButton.isHidden = true
        } else {
            backButton.isHidden = false
        }
        
        skipButton.isHidden = true
        
        // instantiate and display child VC based on layout type
        let storyboard = self.storyboard ?? UIStoryboard(name: "Profile", bundle: nil)
        let contentVC: UIViewController
        
        switch stepData.layoutType {
        case .grid:
            let vc = storyboard.instantiateViewController(withIdentifier: "IndustryGridVC") as! IndustryGridViewController
            vc.items = stepData.options
            vc.stepIndex = index
            contentVC = vc
            
        default:
            let vc = storyboard.instantiateViewController(withIdentifier: "ListSelectionVC") as! ListSelectionViewController
            vc.items = stepData.options
            vc.layoutType = stepData.layoutType
            vc.stepIndex = index
            contentVC = vc
        }
        
        displayContentController(contentVC)
    }
    
    func displayContentController(_ contentVC: UIViewController) {
        if let existingVC = currentChildViewController {
            existingVC.willMove(toParent: nil)
            existingVC.view.removeFromSuperview()
            existingVC.removeFromParent()
        }
        
        addChild(contentVC)
        contentContainer.addSubview(contentVC.view)
        
        contentVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentVC.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            contentVC.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            contentVC.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            contentVC.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor)
        ])
        
        contentVC.didMove(toParent: self)
        currentChildViewController = contentVC
    }
    
    // logic to increment index and update UI
    func goToNextStep() {
        if !isEditMode && currentStepIndex == 2 {
            askForShortBio()
        } else if currentStepIndex < OnboardingDataStore.shared.steps.count - 1 {
            currentStepIndex += 1
            updateUIForStep(index: currentStepIndex)
        } else {
            self.dismiss(animated: true) // Fallback for edit mode
        }
    }
    
    func askForShortBio() {
        let alert = UIAlertController(title: "Short Bio", message: "Please provide a short bio about yourself.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter your short bio here"
        }
        
        let saveAction = UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            guard let bioText = alert.textFields?.first?.text, !bioText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                self?.showAlert(message: "A short bio is required to continue.") {
                    self?.askForShortBio()
                }
                return
            }
            
            OnboardingDataStore.shared.shortBio = bioText
            self?.navigateToProfileScreen()
        }
        
        alert.addAction(saveAction)
        present(alert, animated: true)
    }
    
    // alert helper
    func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Required", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    func navigateToProfileScreen() {
        //Get the current User ID
        guard let userId = SupabaseManager.shared.client.auth.currentUser?.id.uuidString else {
            print("Error: No user logged in during onboarding completion")
            return
        }
        let userKey = "hasCompletedOnboarding_\(userId)"
        UserDefaults.standard.set(true, forKey: userKey)
        
        print("Onboarding completed for user: \(userId). Flag set in UserDefaults.")

        DispatchQueue.main.async {
            if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
               let window = sceneDelegate.window {
                
                // Call helper showMainApp from scene delegate
                sceneDelegate.showMainApp(window: window)
                
                UIView.transition(with: window,
                                duration: 0.5,
                                options: .transitionCrossDissolve,
                                animations: nil,
                                completion: nil)
            }
        }
    }
    
}

