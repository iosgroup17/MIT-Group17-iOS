//
//  LLMModels.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import Foundation

struct UserProfile: Sendable {
    //fields match the 6 steps in OnboardingDataStore
    let role: [String]
    let industry: [String]
    let primaryGoals: [String]
    let contentFormats: [String]
    let toneOfVoice: [String]
    let targetAudience: [String]

    var promptContext: String {
        return """
        USER PROFILE CONTEXT:
        - Role/Identity: \(role.first ?? "Professional")
        - Industry: \(industry.first ?? "General")
        - Primary Goals: \(primaryGoals.joined(separator: ", "))
        - Preferred Content Formats: \(contentFormats.joined(separator: ", "))
        - Tone of Voice: \(toneOfVoice.joined(separator: ", "))
        - Target Audience: \(targetAudience.joined(separator: ", "))
        """
    }
}
