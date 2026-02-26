//
//  LLMModels.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import Foundation

struct UserProfile: Sendable {

    let professionalIdentity: [String]

    let currentFocus: [String]
    
    let industry: [String]
    
    let primaryGoals: [String]
    
    let contentFormats: [String]
  
    let platforms: [String]
    
    let targetAudience: [String]

    var promptContext: String {
//        return """
//        USER PROFILE CONTEXT:
//                - Professional Role: \(professionalIdentity.first ?? "Professional")
//                - Current Work Focus: \(currentFocus.first ?? "General")
//                - Industry: \(industry.first ?? "General")
//                - Primary Goals: \(primaryGoals.joined(separator: ", "))
//                - Preferred Content Formats: \(contentFormats.joined(separator: ", "))
//                - Target Platforms: \(platforms.joined(separator: ", "))
//                - Target Audience: \(targetAudience.joined(separator: ", "))
//        """
        
        return "ROLE:\(professionalIdentity.joined(separator: ",")) | FOCUS:\(currentFocus.joined(separator: ",")) | IND:\(industry.joined(separator: ",")) | GOAL:\(primaryGoals.joined(separator: ",")) | FMT:\(contentFormats.joined(separator: ",")) | PLT:\(platforms.joined(separator: ",")) | AUD:\(targetAudience.joined(separator: ","))"
    }
}


