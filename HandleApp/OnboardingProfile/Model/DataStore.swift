import Foundation
import UIKit

class OnboardingDataStore {

    static let shared = OnboardingDataStore()
    
    private init() {}

    var userAnswers: [Int: Any] = [:]
    
    var steps: [OnboardingStep] = [
        OnboardingStep(
            index: 0,
            title: "What is your primary goal?",
            description: "This helps us prioritize the right results for your brand.",
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(title: "Generate leads", subtitle: "Attract potential customers"),
                OnboardingOption(title: "Build visibility", subtitle: "Grow your reach and influence"),
                OnboardingOption(title: "Attract talent", subtitle: "Find and hire the right people"),
                OnboardingOption(title: "Secure investment", subtitle: "Show value to potential investors")
            ]
        ),
        OnboardingStep(
            index: 1,
            title: "Professional focus",
            description: "Choose the role that best describes your daily work.",
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(title: "Building a startup", iconName: "light-bulb"),
                OnboardingOption(title: "Growing my career", iconName: "id-card"),
                OnboardingOption(title: "Managing a side project", iconName: "briefcase"),
                OnboardingOption(title: "Leading multiple ventures", iconName: "grid_tech")
            ]
        ),
        OnboardingStep(
            index: 2,
            title: "What is your primary area of expertise?",
            description: "We'll suggest content topics based on your field.",
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(title: "Technology & Software", iconName: "grid_tech"),
                OnboardingOption(title: "Marketing & Growth", iconName: "grid_media"),
                OnboardingOption(title: "Finance & Operations", iconName: "grid_finance"),
                OnboardingOption(title: "Design & Product", iconName: "favorite"),
                OnboardingOption(title: "Education & Coaching", iconName: "grid_edu"),
                OnboardingOption(title: "Other Professional Services", iconName: "briefcase")
            ]
        ),

        OnboardingStep(
            index: 3,
            title: "Who is your target audience?",
            description: "Defining this helps the AI tailor the tone to your readers.",
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(title: "Potential Clients", subtitle: "Decision makers and buyers"),
                OnboardingOption(title: "Industry Peers", subtitle: "Other experts and colleagues"),
                OnboardingOption(title: "Recruiters", subtitle: "People looking to hire talent"),
                OnboardingOption(title: "Investors", subtitle: "People looking for the next big thing")
            ]
        ),
        OnboardingStep(
            index: 4,
            title: "Preferred content formats?",
            description: "Which styles of content do you want to create most?",
            layoutType: .multiSelectCards,
            options: [
                OnboardingOption(title: "Thought Leadership", subtitle: "Deep insights and opinions"),
                OnboardingOption(title: "How-to & Tutorials", subtitle: "Educational and helpful guides"),
                OnboardingOption(title: "Personal Stories", subtitle: "Behind the scenes and lessons"),
                OnboardingOption(title: "Industry News", subtitle: "Curated updates and commentary")
            ]
        ),
        OnboardingStep(
            index: 5,
            title: "Where do you want to build your presence?",
            description: "Select the platforms where you are most active.",
            layoutType: .multiSelectCards,
            options: [
                OnboardingOption(title: "LinkedIn", iconName: "icon-linkedin"),
                OnboardingOption(title: "X (Twitter)", iconName: "icon-twitter"),
                OnboardingOption(title: "Instagram", iconName: "icon-instagram"),
                OnboardingOption(title: "Threads", iconName: "icon-threads")
            ]
        ),
        OnboardingStep(
            index: 6, // Adding as a new index
            title: "What is your brand's personality?",
            description: "This determines the tone and 'voice' of your generated posts.",
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(title: "Professional & Authoritative", subtitle: "Polished, expert, and data-backed"),
                OnboardingOption(title: "Casual & Relatable", subtitle: "Friendly, conversational, and authentic"),
                OnboardingOption(title: "Bold & Provocative", subtitle: "Opinionated, daring, and thought-provoking"),
                OnboardingOption(title: "Visionary & Inspiring", subtitle: "Big-picture thinking and motivational")
            ]
        )
    ]
    
    var completionPercentage: Float {
        let totalQuestions = Float(steps.count + 2) // All steps + Name + Bio
        var answeredCount: Float = Float(userAnswers.count)
        if displayName != nil { answeredCount += 1 }
        if shortBio != nil { answeredCount += 1 }
        return answeredCount / totalQuestions
    }
    var profileImage: UIImage?
    var displayName: String?
    var shortBio: String?
    var projects: [String] = []
    
    var socialStatus: [String: Bool] = [
        "Instagram": false,
        "LinkedIn": false,
        "X (Twitter)": false
    ]
    
    
    func saveAnswer(stepIndex: Int, value: Any) {
        userAnswers[stepIndex] = value
        print("Saved for Step \(stepIndex): \(value)")
    }
    
    func getStep(at index: Int) -> OnboardingStep? {
        guard index >= 0 && index < steps.count else { return nil }
        return steps[index]
    }
    
    func syncWithRemoteData(_ responses: [OnboardingResponse]) {
        for response in responses {
            self.userAnswers[response.step_index] = response.selection_tags
        }
    }
    
    func reset() {
        self.userAnswers = [:]
        
        self.profileImage = nil
        self.displayName = nil
        self.shortBio = nil
        self.projects = []
        
        self.socialStatus = [
            "Instagram": false,
            "LinkedIn": false,
            "X (Twitter)": false
        ]
        
        print("OnboardingDataStore has been successfully reset.")
    }
}
