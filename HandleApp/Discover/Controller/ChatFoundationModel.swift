//
//  chatFoundationModel.swift
//  HandleApp
//
//  Created by SDC-USER on 03/02/26.
//

import Foundation
import FoundationModels

struct GenerationRequest {
    let idea: String
    let tone: String
    let platform: String
    let refinementInstruction: String?
}


actor PostGenerationModel {

    static let shared = PostGenerationModel()

    private var session: LanguageModelSession?
    
    private init() {}
    
    private func ensureSession() async throws -> LanguageModelSession {
        if let existingSession = session {
            return existingSession
        }
        
        let model = SystemLanguageModel.default
        let newSession = LanguageModelSession(model: model)
        self.session = newSession
        return newSession
    }

    func generatePost(profile: UserProfile, request: GenerationRequest) async throws -> EditorDraftData {
        
#if targetEnvironment(simulator)

        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        return EditorDraftData(
            postHeading: "A professional workspace",
            platformName: request.platform,
            platformIconName: "doc.text",
            caption: "[Simulator Mock]: Based on '\(request.idea)', here is a \(request.tone) post for \(request.platform).",
            images: ["A professional workspace"],
            hashtags: ["#Simulator", "#SwiftUI"],
            postingTimes: ["10:00 AM"]
        )
        
#else
        

        let session = try await ensureSession()
        

        let prompt = """
        You are an expert Social Media Manager.
        
        \(profile.promptContext)
        
        TASK:
        Write a social media post based on these inputs:
        - Idea: \(request.idea)
        - Tone: \(request.tone)
        - Platform: \(request.platform)
        \(request.refinementInstruction != nil ? "- Refinement: \(request.refinementInstruction!)" : "")
        
        OUTPUT INSTRUCTIONS:
        You must output ONLY valid JSON. No markdown formatting. No introductory text.
        
        Target JSON Structure:
        {
            "platformName": "\(request.platform)",
            "platformIconName": "doc.text", // Use generic doc icon, we map specific ones in UI
            "caption": "The post content here",
            "images": ["Visual description of an image"],
            "hashtags": ["#tag1", "#tag2"],
            "postingTimes": ["Best time to post"]
        }
        """

        let response = try await session.respond(to: prompt)
        

        let cleanJSON = stripMarkdown(from: response.content)
        
        guard let data = cleanJSON.data(using: .utf8) else {
            throw ContentError.jsonParsingFailed
        }
        
        return try JSONDecoder().decode(EditorDraftData.self, from: data)
#endif
    }
        
        private func stripMarkdown(from text: String) -> String {
                var cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanText.hasPrefix("```json") {
                    cleanText = cleanText.replacingOccurrences(of: "```json", with: "")
                } else if cleanText.hasPrefix("```") {
                    cleanText = cleanText.replacingOccurrences(of: "```", with: "")
                }
                if cleanText.hasSuffix("```") {
                    cleanText = String(cleanText.dropLast(3))
                }
                return cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
}

enum ContentError: Error {
    case jsonParsingFailed
    case modelAssetsMissing
    case noJSONFound
}

