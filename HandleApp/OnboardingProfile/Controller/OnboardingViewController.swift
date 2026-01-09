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
        //check if current step has an answer
        let hasAnswer = OnboardingDataStore.shared.userAnswers[currentStepIndex] != nil
        
        //required steps
        if currentStepIndex < 2 && !hasAnswer {
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
            
            //test id call
            await SupabaseManager.shared.savePreference(
                stepIndex: currentStepIndex,
                selections: selectedOptions
            )
            
            DispatchQueue.main.async {
                if self.isEditMode {
                    self.onDismiss?()
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.goToNextStep()
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
        
        backButton.isHidden = (index == 0)
        
        if index < 2 {
            skipButton.isHidden = true
        } else {
            skipButton.isHidden = false
        }
        
        // update question step and progress
        questionLabel.text = stepData.title
        stepLabel.text = "Step \(index + 1) of 6"
        progressView.setProgress(Float(index + 1) / 6.0, animated: true)
        
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
        if currentStepIndex < OnboardingDataStore.shared.steps.count - 1 {
            currentStepIndex += 1
            updateUIForStep(index: currentStepIndex)
        } else {
            print("Navigate to Home Screen")
            navigateToProfileScreen()
        }
    }
    
    // alert helper
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Required", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func navigateToProfileScreen() {
        // save flag to skip onboarding next time
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // using scene delegate to switch root VC
        if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            
            // call helper showMainApp from scene delegate
            sceneDelegate.showMainApp(window: window)
            
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    func savePreferenceToCloud(stepIndex: Int, selections: [String]) {
        guard let userId = client.auth.currentUser?.id else { return }
        
        let response = OnboardingResponse(
            user_id: userId,
            step_index: stepIndex,
            selection_tags: selections
        )
        
        Task {
            do {
                // .upsert handles both initial saving AND updates/changes
                try await client
                    .from("onboarding_responses")
                    .upsert(response)
                    .execute()
                
                print("Successfully synced step \(stepIndex) to Supabase")
                self.goToNextStep()
                
            } catch {
                print("Database error: \(error)")
                // Handle error (e.g., show an alert)
            }
        }
    }
}
