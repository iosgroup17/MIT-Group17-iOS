//
//  ChatModels.swift
//  HandleApp
//
//  Created by SDC-USER on 02/02/26.
//

import Foundation
import UIKit

enum ChatStep {
    case waitingForIdea
    case waitingForTone
    case waitingForPlatform
    case waitingForRefinement
    case finished
}


enum ChatMessageType {
    case text
    case optionPills
    case platformSelection
}


struct Message {
    let id = UUID()
    let text: String
    let isUser: Bool
    let type: ChatMessageType
 
    var options: [String]? = nil
    
    var draft: EditorDraftData? = nil
}
