//
//  LLMModels.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import Foundation

struct UserProfile {
    // These fields correspond to your 6 onboarding questions
    let profession: [String]       // Step 0
    let targetAudience: [String]   // Step 1
    let contentGoals: [String]     // Step 2
    let toneOfVoice: [String]      // Step 3
    let contentTopics: [String]    // Step 4
    let preferredPlatforms: [String] // Step 5
    
    // Helper: Converts this struct into a single text block for the AI prompt
    var promptContext: String {
        return """
        USER CONTEXT:
        - Profession/Identity: \(profession.joined(separator: ", "))
        - Target Audience: \(targetAudience.joined(separator: ", "))
        - Main Goals: \(contentGoals.joined(separator: ", "))
        - Tone of Voice: \(toneOfVoice.joined(separator: ", "))
        - key Topics: \(contentTopics.joined(separator: ", "))
        - Focus Platforms: \(preferredPlatforms.joined(separator: ", "))
        """
    }
}
