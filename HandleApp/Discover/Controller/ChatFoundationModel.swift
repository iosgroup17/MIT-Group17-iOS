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
        
        let session = try await ensureSession()
        

        let prompt = """
            ### SYSTEM
            Role: Lead Executive Ghostwriter.
            CONTEXT: \(await profile.promptContext)

            ### DIRECTIVES
            - Voice: Authentic founder. High utility for \(profile.targetAudience.joined(separator: ", ")).
            - Structure: MUST open with a scroll-stopping hook (bold claim, question, or data).
            - Ban List (NO AI-isms): unleash, delve, tapestry, revolutionize, embark, journey, transform.
            - Compliance: No false claims, medical/financial advice, or discrimination. (Add "Results vary" disclaimer if discussing AI).
            - Images: 2-3 IDs from [img_01 to img_34].

            ### TASK
            Write 1 publish-ready post based on inputs. Format: RAW JSON ONLY. No markdown or intro text.
            - Idea: \(request.idea)
            - Tone: \(request.tone)
            - Platform: \(request.platform)
            \(request.refinementInstruction != nil ? "- Refine: \(request.refinementInstruction!)" : "")

            ### SCHEMA
            {
              "platformName": "\(request.platform)",
              "platformIconName": "Enum ('icon-linkedin', 'icon-x', 'icon-instagram')",
              "caption": "String (Post body. Use \\n for line breaks. No hashtags in body)",
              "images": ["img_XX", "img_XX"],
              "hashtags": ["String (Exactly 4)"],
              "postingTimes": ["String (E.g., 'Monday at 9:00 AM') (Day at Time)"]
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
        
        let model = SystemLanguageModel.default
        let newSession = LanguageModelSession(model: model)
        
        let prompt = """
            ### SYSTEM
            Role: Lead Executive Ghostwriter.
            CONTEXT: \(await profile.promptContext)
            TRENDING TOPIC: \(topicContext)

            ### DIRECTIVES
            - Voice: Authentic founder. High utility for \(profile.targetAudience.joined(separator: ", ")). No buzzwords.
            - Structure: MUST open with a scroll-stopping hook leveraging the TRENDING TOPIC.
            - Ban List (NO AI-isms): unleash, delve, tapestry, revolutionize, embark, journey, transform.
            - Compliance: No false claims, medical/financial advice, or discrimination. (Add "Results vary" disclaimer if discussing AI).
            - Images: 2-3 IDs from [img_01 to img_34].


            ### TASK
            Write 1 publish-ready post focusing on the TRENDING TOPIC. Format: RAW JSON ONLY. No markdown or intro text.
            - User Angle: \(request.idea)
            - Tone: \(request.tone)
            - Platform: \(request.platform)
            \(request.refinementInstruction != nil ? "- Refine: \(request.refinementInstruction!)" : "")

            ### SCHEMA
            {
                "platformName": "\(request.platform)",
                "platformIconName": "Enum ('icon-linkedin', 'icon-x', 'icon-instagram')",
                "caption": "String (Post body. Use \\n for line breaks. No hashtags in body)",
                "images": ["img_XX", "img_XX"],
                "hashtags": ["String (Exactly 4)"],
                "postingTimes": ["String (E.g., 'Mon 9:00 AM') (Day at Time)"]
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
    }
}

