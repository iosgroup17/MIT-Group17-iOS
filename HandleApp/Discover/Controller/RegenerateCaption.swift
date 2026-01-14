//
//  RegenerateCaption.swift
//  HandleApp
//
//  Created by SDC-USER on 16/12/25.
//

import Foundation
import FoundationModels

protocol CaptionGenerator {
    func regenerate(_ text: String, tone: String) async throws -> String
}

actor RegenerateCaption: CaptionGenerator {
    
    private var session: LanguageModelSession?
    
    private func ensureSession() async throws -> LanguageModelSession {
        if let existingSession = session { return existingSession }
        
        let model = SystemLanguageModel.default

 
        let newSession = LanguageModelSession(model: model)
        self.session = newSession
        return newSession
    }
    
    func regenerate(_ text: String, tone: String = "engaging") async throws -> String {
        
#if targetEnvironment(simulator)
        // Fake a delay to simulate AI thinking
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        return " [Simulated AI]: This is a mock response because the Simulator cannot run Foundation Models. The original text was: '\(text)'"
#else
        
        //Real Device Logic
        let session = try await ensureSession()
        
        let prompt = """
                        Rewrite the caption below to be slightly longer while preserving its original meaning and style, and adjusting it to the specified tone \(tone).
                        Maintain a natural, polished flow.
                        Return only the rewritten caption, with no explanations or additional text.
                
                Caption: "\(text)"
                """
        
        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            // If the model is missing on the real device
            print("Model Error: \(error)")
            throw CaptionError.modelAssetsMissing
        }
#endif
    }
    

}

enum CaptionError: Error {
    case deviceNotSupported
    case modelAssetsMissing
}
