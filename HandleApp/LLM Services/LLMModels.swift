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

    // MARK: - Computed Context
    var promptContext: String {
        return """
        USER PROFILE CONTEXT:
                - Professional Role: \(professionalIdentity.first ?? "Professional")
                - Current Work Focus: \(currentFocus.first ?? "General")
                - Industry: \(industry.first ?? "General")
                - Primary Goals: \(primaryGoals.joined(separator: ", "))
                - Preferred Content Formats: \(contentFormats.joined(separator: ", "))
                - Target Platforms: \(platforms.joined(separator: ", "))
                - Target Audience: \(targetAudience.joined(separator: ", "))
        """
    }
}


