import Foundation
import UIKit

class OnboardingDataStore {

    static let shared = OnboardingDataStore()
    
    private init() {}

    var userAnswers: [Int: Any] = [:]
    
    var steps: [OnboardingStep] = [

        OnboardingStep(
            index: 0,
            title: "How do you identify professionally?",
            description: nil,
            layoutType: .singleSelectChips,
            options: [
                OnboardingOption(title: "Founder", iconName: "light-bulb"),
                OnboardingOption(title: "Employee", iconName: "id-card")
            ]
        ),

        OnboardingStep(
            index: 1,
            title: "What are you working on right now?",
            description: nil,
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(title: "Building a startup or product"),
                OnboardingOption(title: "Working in a full-time role"),
                OnboardingOption(title: "Growing a side project"),
                OnboardingOption(title: "Juggling multiple things")
            ]
        ),

        OnboardingStep(
            index: 2,
            title: "Which domain best fits your work?",
            description: nil,
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(title: "Technology & Software", iconName: "grid_tech"),
                OnboardingOption(title: "Marketing, Branding & Growth", iconName: "grid_media"),
                OnboardingOption(title: "Finance, Strategy & Operations", iconName: "grid_finance"),
                OnboardingOption(title: "Design, Product & UX", iconName: "favorite"),
                OnboardingOption(title: "Education, Coaching & Knowledge", iconName: "grid_edu"),
                OnboardingOption(title: "Media, Content & Community", iconName: "hospitality")
            ]
        ),

        OnboardingStep(
            index: 3,
            title: "What’s your main goal right now?",
            description: nil,
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(
                    title: "Build visibility",
                    subtitle: "Grow your professional Presence and Reach"
                ),
                OnboardingOption(
                    title: "Generate leads",
                    subtitle: "Attract potential Customers and Inquiries"
                ),
                OnboardingOption(
                    title: "Recruit candidates",
                    subtitle: "Find and engage talented Professionals"
                ),
                OnboardingOption(
                    title: "Launch/promote",
                    subtitle: "Announce products features or initiatives"
                ),
                OnboardingOption(
                    title: "Attract investors",
                    subtitle: "Build credibility with funding sources"
                )
        ]),

        OnboardingStep(
            index: 4,
            title: "What content feels natural to you?",
            description: "Select all that apply.",
            layoutType: .multiSelectCards,
            options: [
                OnboardingOption(title: "Thought leadership", subtitle: "Share insights and perspectives", iconName: "light-bulb"),
                OnboardingOption(title: "Educational", subtitle: "Teach your audience something new", iconName: "open-book"),
                OnboardingOption(title: "Behind the Scenes", subtitle: "Show your process and culture", iconName: "directors-chair"),
                OnboardingOption(title: "Case Studies", subtitle: "Highlight results and wins", iconName: "caseStudies"),
                OnboardingOption(title: "Interactive Q&A", subtitle: "Engage with your community", iconName: "speech-bubble")
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
            title: "Who should your content reach?",
            description: "Select all that apply.",
            layoutType: .multiSelectCards,
            options: [
                OnboardingOption(title: "New Prospects", subtitle: "People discovering you for the first time"),
                OnboardingOption(title: "Current Customers", subtitle: "Those already using your product"),
                OnboardingOption(title: "Investors", subtitle: "Individuals considering funding you"),
                OnboardingOption(title: "Job Candidates", subtitle: "Potential hires exploring opportunities"),
                OnboardingOption(title: "Professional Peers", subtitle: "Colleagues in your industry"),
                OnboardingOption(title: "Wider Community", subtitle: "General audience")
            ]
        )
    ]

    var profileImage: UIImage?
    var displayName: String?
    var shortBio: String?
    var projects: [String] = []
    
    // Social Connections (Status)
    var socialStatus: [String: Bool] = [
        "Instagram": false,
        "LinkedIn": false,
        "X (Twitter)": false
    ]
    
    // Helper to calculate "Profile Completion" %
    var completionPercentage: Float {
        var totalPoints = 0
        var earnedPoints = 0
        
        // Quiz Points (6 Questions)
        totalPoints += 6
        earnedPoints += userAnswers.count
        
        // Profile Points (Name, Bio, Image)
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
