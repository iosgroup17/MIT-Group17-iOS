import Foundation

/// One row in the "Complete your profile" checklist. Backed either by the
/// in-memory/UserDefaults name & bio, or by one of the Supabase onboarding steps.
enum ProfileChecklistItem {
    case displayName
    case shortBio
    case step(Int)

    /// Short label shown in the card / checklist (not the full onboarding question).
    var title: String {
        switch self {
        case .displayName: return "Display Name"
        case .shortBio: return "Short Bio"
        case .step(let index):
            switch index {
            case 0: return "Primary Goal"
            case 1: return "Professional Focus"
            case 2: return "Area of Expertise"
            case 3: return "Target Audience"
            case 4: return "Content Formats"
            case 5: return "Platforms"
            case 6: return "Brand Tone"
            default: return "Question \(index + 1)"
            }
        }
    }

    /// The currently saved value, or nil if unanswered.
    var currentValue: String? {
        let store = OnboardingDataStore.shared
        switch self {
        case .displayName:
            return store.displayName?.nonEmpty
        case .shortBio:
            return store.shortBio?.nonEmpty
        case .step(let index):
            if let tags = store.userAnswers[index] as? [String], !tags.isEmpty {
                return tags.joined(separator: ", ")
            }
            if let tag = store.userAnswers[index] as? String, !tag.isEmpty {
                return tag
            }
            return nil
        }
    }

    var isComplete: Bool {
        return currentValue != nil
    }
}

/// The full ordered checklist plus convenience completion math.
enum ProfileChecklist {

    static let items: [ProfileChecklistItem] = [
        .displayName,
        .shortBio,
        .step(0), .step(1), .step(2), .step(3), .step(4), .step(5), .step(6)
    ]

    static var completedCount: Int {
        items.filter { $0.isComplete }.count
    }

    static var totalCount: Int {
        items.count
    }

    static var isComplete: Bool {
        completedCount == totalCount
    }

    static var fractionComplete: Float {
        guard totalCount > 0 else { return 1 }
        return Float(completedCount) / Float(totalCount)
    }
}

private extension String {
    /// Returns nil for empty / whitespace-only strings.
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
