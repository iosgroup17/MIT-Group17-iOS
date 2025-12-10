import UIKit

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
    private var currentChildViewController: UIViewController?
    var isEditMode: Bool = false
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIForStep(index: currentStepIndex)
        
        if isEditMode {
            setupForEditing()
        }
    }
    
    func setupForEditing() {
        // 1. Hide "Quiz" Context
        progressView.isHidden = true
        stepLabel.isHidden = true
        skipButton.isHidden = true
        
        nextButton.setTitle("Save Update", for: .normal)
        
        // 2. Hide Back Button (Because they can just swipe down to cancel)
        backButton.isHidden = true
        
        // 3. Change "Next" to "Save"
        nextButton.setTitle("Save", for: .normal)
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        // 1. Check if the user has answered the current question
        let hasAnswer = OnboardingDataStore.shared.userAnswers[currentStepIndex] != nil
        
        // 2. COMPULSORY CHECK: If Step 1 or 2 (index < 2) AND no answer...
        if currentStepIndex < 2 && !hasAnswer {
            // Show Alert and STOP
            showAlert(message: "This step is required. Please select an option.")
            return
        }
        
        if isEditMode {
            // 1. Run the "Reload" command provided by the Profile screen
            onDismiss?()

            // 2. Close the screen
            dismiss(animated: true, completion: nil)
        } else {
            goToNextStep()
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
        
        if let desc = stepData.description, !desc.isEmpty {
            descLabel.text = desc
            descLabel.isHidden = false
        } else {
            // If no description, hide the label so it doesn't take up space
            descLabel.text = ""
            descLabel.isHidden = true
        }
        
        if index == 0 {
            backButton.isHidden = true
        } else {
            backButton.isHidden = false
        }
        
        backButton.isHidden = (index == 0)
        
        if index < 2 {
            skipButton.isHidden = true
        } else {
            skipButton.isHidden = false
        }
        
        //Update Header
        questionLabel.text = stepData.title
        stepLabel.text = "Step \(index + 1) of 6"
        progressView.setProgress(Float(index + 1) / 6.0, animated: true)
        
        //Instantiate from Storyboard
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
        // 3. Display it
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
    
    // Logic to increment index and update UI
    func goToNextStep() {
        if currentStepIndex < OnboardingDataStore.shared.steps.count - 1 {
            currentStepIndex += 1
            updateUIForStep(index: currentStepIndex)
        } else {
            print("Navigate to Home Screen")
            navigateToProfileScreen()
        }
    }
    
    // Simple Alert Helper
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Required", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func navigateToProfileScreen() {
        // 1. Save the flag so next time we skip onboarding
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // 2. Access the SceneDelegate to swap the root view controller
        if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            
            // 3. Call the helper we wrote in SceneDelegate
            sceneDelegate.showMainApp(window: window)
            
            // 4. Smooth Transition
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
}
