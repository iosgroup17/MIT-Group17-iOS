import Foundation
import UIKit

class OnboardingDataStore {

    static let shared = OnboardingDataStore()
    
    private init() {}

    var userAnswers: [Int: Any] = [:]
    
    var steps: [OnboardingStep] = [
        
        OnboardingStep(
            index: 0,
            title: "Select a Role to get a Personalized Setup.",
            description: nil,
            layoutType: .singleSelectChips,
            options: [
                OnboardingOption(title: "Founder", iconName: "light-bulb"),
                OnboardingOption(title: "Employee", iconName: "id-card")
            ]
        ),

        OnboardingStep(
            index: 1,
            title: "What’s your primary goal right now?",
            description: nil,
            layoutType: .singleSelectCards,
            options: [
                OnboardingOption(title: "Build brand awareness", subtitle: "Grow your professional Presence and Reach"),
                OnboardingOption(title: "Generate leads", subtitle: "Attract potential Customers and Inquiries"),
                OnboardingOption(title: "Recruit candidates", subtitle: "Find and engage talented Professionals"),
                OnboardingOption(title: "Launch/promote", subtitle: "Announce products features or initiatives"),
                OnboardingOption(title: "Attract investors", subtitle: "Build credibility with funding sources"),
            ]
        ),

        OnboardingStep(
            index: 2,
            title: "Which industry do you work in?",
            description: nil,
            layoutType: .grid,
            options: [
                // Providing top choices for the Grid. Search logic will be separate.
                OnboardingOption(title: "Tech", iconName: "grid_tech"),
                OnboardingOption(title: "Finance", iconName: "grid_finance"),
                OnboardingOption(title: "Healthcare", iconName: "grid_health"),
                OnboardingOption(title: "Education", iconName: "grid_edu"),
                OnboardingOption(title: "Food", iconName: "grid_food"),
                OnboardingOption(title: "Hospitality", iconName: "grid_hosp"),
                OnboardingOption(title: "Media", iconName: "grid_media"),
                OnboardingOption(title: "Legal", iconName: "grid_legal"),
                OnboardingOption(title: "Other", iconName: "grid_search")
            ]
        ),
        
        OnboardingStep(
            index: 3,
            title: "Which Content Formats feel natural?",
            description:"Select all that apply.",
            layoutType: .multiSelectCards,
            options: [
                OnboardingOption(title: "Thought leadership", subtitle: "Share insights and perspectives", iconName: "light-bulb"),
                OnboardingOption(title: "Educational", subtitle: "Teach your audience something new", iconName: "open-book"),
                OnboardingOption(title: "Behind the Scenes", subtitle: "Show your process and culture", iconName: "directors-chair"),
                OnboardingOption(title: "Case Studies", subtitle: "Highlight results and wins", iconName: "caseStudies"),
                OnboardingOption(title: "Interactive Q&A", subtitle: "Engage with your community", iconName: "speech-bubble")
            ]
        ),
        
        // Note: Title = Left Label, Subtitle = Right Label
        OnboardingStep(
            index: 4,
            title: "Which tone should your posts convey?",
            description: "Select 2-3 adjectives that describe your voice.",
            layoutType: .multiSelectCards,
            options: [
                    OnboardingOption(title: "Professional", iconName: "briefcase"),
                    OnboardingOption(title: "Friendly", iconName: "hi"),
                    OnboardingOption(title: "Witty", iconName: "happy"),
                    OnboardingOption(title: "Authoritative", iconName: "favorite"),
                    OnboardingOption(title: "Empathetic", iconName: "hearty"),
                    OnboardingOption(title: "Direct", iconName: "signposts")
            ]
        ),
        
        OnboardingStep(
            index: 5,
            title: "Who’s your primary audience?",
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
    var projects: [String] = [] // List of project names
    
    // 3. Social Connections (Status)
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
}
