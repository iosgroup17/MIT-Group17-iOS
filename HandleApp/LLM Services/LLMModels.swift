//
//  LLMModels.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import Foundation

struct UserProfile: Sendable {
    // MARK: - Onboarding Data Fields
    
    // Step 0: How do you identify professionally? (e.g., Founder, Employee)
    let professionalIdentity: [String]
    
    // Step 1: What are you working on? (e.g., Startup, Full-time role)
    let currentFocus: [String]
    
    // Step 2: Industry/Domain
    let industry: [String]
    
    // Step 3: Main Goal
    let primaryGoals: [String]
    
    // Step 4: Content Formats
    let contentFormats: [String]
    
    // Step 5: Platforms (LinkedIn, X, etc.)
    let platforms: [String]
    
    // Step 6: Target Audience
    let targetAudience: [String]
    
    let acceptedSuggestions: [AcceptedSuggestion]

    // MARK: - Computed Context
    var promptContext: String {
        let suggestionText = acceptedSuggestions.map {
                    "- \($0.title): \($0.detail) (Rec: \($0.recommended.description))"
                }.joined(separator: "\n")
        return """
        USER PROFILE CONTEXT:
                - Professional Role: \(professionalIdentity.first ?? "Professional")
                - Current Work Focus: \(currentFocus.first ?? "General")
                - Industry: \(industry.first ?? "General")
                - Primary Goals: \(primaryGoals.joined(separator: ", "))
                - Preferred Content Formats: \(contentFormats.joined(separator: ", "))
                - Target Platforms: \(platforms.joined(separator: ", "))
                - Target Audience: \(targetAudience.joined(separator: ", "))
                
                STRATEGIES:
                \(suggestionText)
        """
    }
}


struct AcceptedSuggestion: Codable, Sendable {
    let title: String
    let detail: String
    let recommended: RecommendedContent
    let impactScore: String

    enum CodingKeys: String, CodingKey {
        case title = "suggestion_title"
        case detail = "suggestion_detail"
        case recommended
        case impactScore = "impact_score"
    }
}

enum RecommendedContent: Codable, Sendable {
    case list([String])
    case text(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([String].self) {
            self = .list(array)
        } else if let string = try? container.decode(String.self) {
            self = .text(string)
        } else {
            throw DecodingError.typeMismatch(RecommendedContent.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]"))
        }
    }
    
    // Helper to get a string representation for your promptContext
    var description: String {
        switch self {
        case .list(let items): return items.joined(separator: ", ")
        case .text(let text): return text
        }
    }
}
