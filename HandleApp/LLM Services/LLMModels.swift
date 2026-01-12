//
//  LLMModels.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import Foundation

struct UserProfile {
    // These fields match the 6 steps in OnboardingDataStore
    let role: [String]          // Step 0
    let industry: [String]      // Step 1
    let primaryGoals: [String]  // Step 2
    let contentFormats: [String]// Step 3
    let toneOfVoice: [String]   // Step 4
    let targetAudience: [String]// Step 5
    
    // Dynamic System Prompt
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
