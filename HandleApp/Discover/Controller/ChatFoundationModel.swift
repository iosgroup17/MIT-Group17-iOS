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
            ACT AS: Lead Executive Ghostwriter for Founders.

            PROFILE: \(await profile.promptContext)

            STYLE REFERENCE: 

            GUIDELINES:
            1. AUTHENTICITY: Write as a founder with real skin in the game. No corporate buzzwords.
            2. NO AI-isms: Never use "unleash," "delve," "tapestry," "revolutionize," "embark," "journey," "transform," or similar.
            3. VALUE-FIRST: Every post delivers clear utility for \(profile.targetAudience.joined(separator: ", "))
            4. HOOK-REQUIRED: First line must be a scroll-stopping hook (bold claim, question, or data point).
            5. PROFESSIONAL: Respectful tone, no harassment, stereotypes, or offensive content.

            REGULATORY COMPLIANCE (MANDATORY):
            - NO false claims, guarantees, or misleading statements
            - NO medical/health advice unless founder is licensed professional
            - NO financial investment advice or "get rich quick" promises
            - NO discriminatory language (race, gender, religion, etc.)
            - NO promotion of illegal activities
            - Include disclaimers if discussing AI tools: "Results vary based on implementation"

            TASK: Write 1 publish-ready social media post for:
            - Idea: \(request.idea)
            - Tone: \(request.tone)
            - Platform: \(request.platform)
            \(request.refinementInstruction != nil ? "- Refine: \(request.refinementInstruction!)" : "")

            OUTPUT: ONLY valid JSON. No other text.

            {
              "platformName": "\(request.platform)",
              "platformIconName": "doc.text",
              "caption": "Post content here. Use \\n for line breaks. No hashtags.",
              "images": ["1 detailed visual description matching founder's industry"],
              "hashtags": ["#Tag1", "#Tag2", "#Tag3"],
              "postingTimes": ["Day at Time", "Day at Time"]
            }
            """

        let response = try await session.respond(to: prompt)
        

        let cleanJSON = stripMarkdown(from: response.content)
        
        guard let data = cleanJSON.data(using: .utf8) else {
            throw ContentError.jsonParsingFailed
        }
        
        return try await MainActor.run {
            try JSONDecoder().decode(EditorDraftData.self, from: data)
        }
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


extension PostGenerationModel {
   
    func generateTopicBasedPost(profile: UserProfile, topicContext: String, request: GenerationRequest) async throws -> EditorDraftData {
        
#if targetEnvironment(simulator)
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        return EditorDraftData(
            postHeading: "Trending Post Idea",
            platformName: request.platform,
            platformIconName: "doc.text",
            caption: "[Simulator Mock]: Based on the trending topic '\(topicContext)' and idea '\(request.idea)', here is a \(request.tone) post for \(request.platform).",
            images: ["A relevant trend visual"],
            hashtags: ["#Simulator", "#Trending"],
            postingTimes: ["10:00 AM"]
        )
#else
        
        // Explicitly starting a NEW session as requested
        let model = SystemLanguageModel.default
        let newSession = LanguageModelSession(model: model)
        
        let prompt = """
            ACT AS: Lead Executive Ghostwriter for Founders.
            
            PROFILE: \(await profile.promptContext)
            TRENDING TOPIC CONTEXT: \(topicContext)
            
            GUIDELINES:
            1. AUTHENTICITY: Write as a founder with real skin in the game. No corporate buzzwords.
            2. NO AI-isms: Never use "unleash," "delve," "tapestry," "revolutionize," "embark," "journey," "transform," or similar.
            3. VALUE-FIRST: Every post delivers clear utility for \(profile.targetAudience.joined(separator: ", "))
            4. HOOK-REQUIRED: First line must be a scroll-stopping hook leveraging the Trending Topic.
            5. PROFESSIONAL: Respectful tone, no harassment, stereotypes, or offensive content.
            
            REGULATORY COMPLIANCE (MANDATORY):
            - NO false claims, guarantees, or misleading statements
            - NO medical/health advice unless founder is licensed professional
            - NO financial investment advice or "get rich quick" promises
            - Include disclaimers if discussing AI tools: "Results vary based on implementation"
            
            TASK: Write 1 publish-ready social media post focusing on the provided TRENDING TOPIC.
            - User's Custom Angle: \(request.idea)
            - Tone: \(request.tone)
            - Platform: \(request.platform)
            \(request.refinementInstruction != nil ? "- Refine: \(request.refinementInstruction!)" : "")
            
            OUTPUT: ONLY valid JSON. No other text.
            
            {
              "platformName": "\(request.platform)",
              "platformIconName": "doc.text",
              "caption": "Post content here. Use \\n for line breaks. No hashtags.",
              "images": ["1 detailed visual description matching founder's industry"],
              "hashtags": ["#Tag1", "#Tag2", "#Tag3"],
              "postingTimes": ["Day at Time", "Day at Time"]
            }
            """
        
        let response = try await newSession.respond(to: prompt)
        let cleanJSON = stripMarkdown(from: response.content)
        
        guard let data = cleanJSON.data(using: .utf8) else {
            throw ContentError.jsonParsingFailed
        }
        
        return try await MainActor.run {
            try JSONDecoder().decode(EditorDraftData.self, from: data)
        }
#endif
    }
}

