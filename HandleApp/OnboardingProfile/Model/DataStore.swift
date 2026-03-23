import Foundation
import UIKit

class OnboardingDataStore {

    static let shared = OnboardingDataStore()
    
    private init() {}

    var userAnswers: [Int: Any] = [:]
    
    var steps: [OnboardingStep] = [

        OnboardingStep(
            index: 0,
            title: "What best describes your role?",
            description: nil,
            layoutType: .singleSelectChips,
            options: [
                OnboardingOption(title: "Founder", iconName: "light-bulb"),
                OnboardingOption(title: "Employee", iconName: "id-card")
            ]
        ),

        OnboardingStep(
            index: 1,
            title: "What are you doing right now?",
            description: nil,
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(title: "Building a startup or product"),
                OnboardingOption(title: "Working full-time"),
                OnboardingOption(title: "Working on a side project"),
                OnboardingOption(title: "Doing multiple things")
            ]
        ),

        OnboardingStep(
            index: 2,
            title: "Which area do you work in?",
            description: nil,
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(title: "Technology & Software", iconName: "grid_tech"),
                OnboardingOption(title: "Marketing & Growth", iconName: "grid_media"),
                OnboardingOption(title: "Finance & Operations", iconName: "grid_finance"),
                OnboardingOption(title: "Design & Product", iconName: "favorite"),
                OnboardingOption(title: "Education & Coaching", iconName: "grid_edu"),
                OnboardingOption(title: "Media & Content", iconName: "hospitality")
            ]
        ),

        OnboardingStep(
            index: 3,
            title: "What is your main goal right now?",
            description: nil,
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(
                    title: "Build visibility",
                    subtitle: "Get noticed and grow your reach"
                ),
                OnboardingOption(
                    title: "Generate leads",
                    subtitle: "Get potential customers and inquiries"
                ),
                OnboardingOption(
                    title: "Hire people",
                    subtitle: "Find and attract good candidates"
                ),
                OnboardingOption(
                    title: "Launch or promote",
                    subtitle: "Share your product or updates"
                ),
                OnboardingOption(
                    title: "Attract investors",
                    subtitle: "Show value to potential investors"
                )
        ]),

        OnboardingStep(
            index: 4,
            title: "What type of content do you like to create?",
            description: "Select all that apply.",
            layoutType: .multiSelectCards,
            options: [
                OnboardingOption(title: "Thought leadership", subtitle: "Share your ideas and opinions", iconName: "light-bulb"),
                OnboardingOption(title: "Educational", subtitle: "Teach something useful", iconName: "open-book"),
                OnboardingOption(title: "Behind the scenes", subtitle: "Show your work or process", iconName: "directors-chair"),
                OnboardingOption(title: "Case studies", subtitle: "Share results or success stories", iconName: "caseStudies"),
                OnboardingOption(title: "Q&A", subtitle: "Answer questions and interact", iconName: "speech-bubble")
            ]
        ),

        OnboardingStep(
            index: 5,
            title: "Where do you want to post?",
            description: "Select all that apply.",
            layoutType: .multiSelectCards,
            options: [
                OnboardingOption(title: "LinkedIn", iconName: "icon-linkedin"),
                OnboardingOption(title: "X (Twitter)", iconName: "icon-twitter"),
                OnboardingOption(title: "Instagram", iconName: "icon-instagram")
            ]
        ),

        OnboardingStep(
            index: 6,
            title: "Who do you want to reach?",
            description: "Select all that apply.",
            layoutType: .multiSelectCards,
            options: [
                OnboardingOption(title: "New prospects", subtitle: "People who don’t know you yet"),
                OnboardingOption(title: "Current customers", subtitle: "People already using your product"),
                OnboardingOption(title: "Investors", subtitle: "People who may fund you"),
                OnboardingOption(title: "Job candidates", subtitle: "People looking to work with you"),
                OnboardingOption(title: "Peers", subtitle: "Others in your field"),
                OnboardingOption(title: "General audience", subtitle: "Anyone interested")
            ]
        )
    ]

    var profileImage: UIImage?
    var displayName: String?
    var shortBio: String?
    var projects: [String] = []
    
    var socialStatus: [String: Bool] = [
        "Instagram": false,
        "LinkedIn": false,
        "X (Twitter)": false
    ]
    
    var completionPercentage: Float {
        var totalPoints = 0
        var earnedPoints = 0
        
        totalPoints += 6
        earnedPoints += userAnswers.count
        
        totalPoints += 3
        if displayName != nil { earnedPoints += 1 }
        if shortBio != nil { earnedPoints += 1 }
        if profileImage != nil { earnedPoints += 1 }
        
        return Float(earnedPoints) / Float(totalPoints)
    }
    
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
