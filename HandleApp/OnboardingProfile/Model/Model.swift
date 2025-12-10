import Foundation

// Defines the type of UI needed for the step
enum OnboardingLayoutType {
    case singleSelectChips  // Role
    case singleSelectCards  // Goal
    case grid               // Industry
    case multiSelectCards   // Post Formats, Audience
    case sliders            // Tone
}

// Represents a single choice (e.g., "Founder" or "Casual <-> Formal")
struct OnboardingOption {
    let id: String
    let title: String
    let subtitle: String? 
    let iconName: String?
    
    init(title: String, subtitle: String? = nil, iconName: String? = nil) {
        self.id = title // Using title as ID for simplicity
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
    }
}

// Represents one full screen in the onboarding flow
struct OnboardingStep {
    let index: Int
    let title: String
    let description: String?
    let layoutType: OnboardingLayoutType
    let options: [OnboardingOption]
}
