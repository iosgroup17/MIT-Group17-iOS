//
//  ChatModels.swift
//  HandleApp
//
//  Created by SDC-USER on 02/02/26.
//

import Foundation
import UIKit

// 1. The Stages of your Conversation
// This tracks "Where are we?" so the code knows what to ask next.
enum ChatStep {
    case waitingForIdea       // Step 1: User types idea
    case waitingForTone       // Step 2: User selects Tone (Pills)
    case waitingForPlatform   // Step 3: User selects Platform (Cards)
    case waitingForRefinement // Step 4: (Optional) Refine draft
    case finished             // Step 5: Show Final Result
}

// 2. The Type of Message to display
// This tells the TableView which Cell design to use.
enum ChatMessageType {
    case text                 // Standard bubble (Blue/Gray)
    case optionPills          // Horizontal scrollable pills (e.g. "Professional", "Casual")
    case platformSelection    // Vertical list of cards (LinkedIn, Instagram)
}

// 3. The Upgraded Message Struct
struct Message {
    let id = UUID()           // Unique ID for safe updates
    let text: String          // The main text (e.g., "What tone?")
    let isUser: Bool          // True = Right side (Blue), False = Left side (Gray)
    let type: ChatMessageType // Is it text, pills, or cards?
    
    // -- Optional Data for specific types --
    
    // If type == .optionPills, this holds ["Casual", "Professional", "Bold"]
    var options: [String]? = nil
    
    // If type == .text (Final Result), this holds the Draft data to show the "Open Editor" button
    var draft: EditorDraftData? = nil
}
