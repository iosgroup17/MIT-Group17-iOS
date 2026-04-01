//
//  publishReadyPostEngine.swift
//  HandleApp
//
//  Created by SDC-USER on 05/02/26.
//


import Foundation
import FoundationModels

actor OnDevicePostEngine {
    static let shared = OnDevicePostEngine()
    
    private init() {}
    
    private func createFreshSession() -> LanguageModelSession {
            return LanguageModelSession(model: SystemLanguageModel.default)
        }
 
    func generatePublishReadyPosts(context: UserProfile) async throws -> [PublishReadyPost] {
        let session = createFreshSession()
        
        let prompt = """
                Context: \(await context.promptContext)
                Task: Output a RAW JSON array of exactly 6 social media posts (Contrarian, How-To, Personal, Prediction, Behind-Scenes, Tool).

                RULES:
                - Tone: Authentic founder voice, high utility. No false claims, medical advice, or deepfakes.
                - Mix: 2 'icon-linkedin', 2 'icon-x', 2 'icon-instagram'.
                - post_heading: Max 3 words. Crisp gist.
                - caption: ~2 lines. Catchy, precise teaser. No hashtags.
                - hashtags: 2 long compound tags OR 3 short tags.
                - prediction_text: Max 25 chars. State the exact benefit to the reader.
                - post_image: Instagram requires 1 random stock image. The path MUST be exactly between 'img_01' and 'img_34'. Others MUST be null.

                OUTPUT FORMAT:
                {
                  "posts": [
                    {
                      "post_heading": "String",
                      "platform_icon": "Enum('icon-linkedin', 'icon-x', 'icon-instagram')",
                      "caption": "String",
                      "hashtags": ["#String"],
                      "prediction_text": "String",
                      "post_image": [{"type": "stock", "path": "img_XX"}] // XX is strictly 01 through 34, or null
                    }
                  ]
                }

                EXAMPLE:
                {
                  "posts": [
                    {
                      "post_heading": "Stop Chasing Features",
                      "platform_icon": "icon-linkedin",
                      "caption": "More features don't equal more value. We cut our roadmap in half and doubled retention. Here is the exact framework we used.",
                      "hashtags": ["#ProductStrategy", "#FounderInsights"],
                      "prediction_text": "Save months of dev time",
                      "post_image": null
                    },
                    {
                      "post_heading": "Design Systems Win",
                      "platform_icon": "icon-instagram",
                      "caption": "Stop rebuilding UI components from scratch every sprint. A solid design system scales your output 10x without adding headcount.",
                      "hashtags": ["#DesignSystems", "#Scale", "#UIUX"],
                      "prediction_text": "Ship UI 10x faster today",
                      "post_image": [ { "type": "stock", "path": "img_14" } ]
                    }
                  ]
                }
                """
        
        
        let response = try await session.respond(to: prompt)

        guard var jsonString = extractAndCleanJSON(from: response.content) else {
                throw NSError(domain: "Decoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "No JSON found"])
            }

            
            if !jsonString.contains("\"posts\":") {
                if jsonString.hasPrefix("{") {
             
                    jsonString = "{\"posts\": [\(jsonString)]}"
                } else if jsonString.hasPrefix("[") {
              
                    jsonString = "{\"posts\": \(jsonString)}"
                }
            }
        
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "Decoder", code: 1, userInfo: [NSLocalizedDescriptionKey: "String to Data conversion failed"])
        }

        print("Cleaned AI JSON:\n\(jsonString)")
        

        do {
            struct ResponseWrapper: Codable { let posts: [PublishReadyPost] }
            let decoded = try JSONDecoder().decode(ResponseWrapper.self, from: data)
            return decoded.posts
        } catch {
            print("Decoding Error: \(error)")

            print("Offending JSON: \(jsonString)")
            throw error
        }
    }
    

    private func extractAndCleanJSON(from text: String) -> String? {

        var cleaned = text.replacingOccurrences(of: "```json", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        

        guard let firstIndex = cleaned.firstIndex(of: "{"),
              let lastIndex = cleaned.lastIndex(of: "}") else {
            return nil
        }
        
        guard firstIndex < lastIndex else { return nil }
        
        let jsonSubstring = cleaned[firstIndex...lastIndex]
        return String(jsonSubstring)
    }
}

extension OnDevicePostEngine {

    func refinePostForEditor(post: PublishReadyPost, context: UserProfile) async throws -> EditorDraftData {
        let session = createFreshSession()
        
        let platformName = post.platformIcon.contains("linkedin") ? "LinkedIn" : (post.platformIcon.contains("instagram") ? "Instagram" : "X")
        
        
        let prompt = """
         ### ROLE
         Expert Social Media Elite Writer for Founders.
         CONTEXT: \(await context.promptContext)

         ### INPUT DRAFT
         - Platform: \(platformName)
         - Concept: "\(post.caption)"

         ### MANDATORY GUIDELINES
         1. Voice: Human, authoritative, experience-led. NO AI-isms (Unleash, Delve, Tapestry, Revolutionize).
         2. Legal (India 2026): No false claims, unverified stats, or medical/financial advice.
         3. Content: Expand draft to 80-120 words. High "Alpha" with line breaks. 

         ### UI CONSTRAINTS (Strict)
         - Structure: Short paragraphs ONLY (1-2 sentences max). Use \n\n for double spacing between points. READABILITY MAXIMUM.
         - Caption: 80-120 words. Max 3 emojis.
         - Images: 2-3 random paths from [img_01 to img_34].
         - Hashtags: 4 compound tags (e.g. #TechTips), ≤12 chars each.

         ### OUTPUT SCHEMA (JSON Only)
         {
           "post_heading": "\(post.postHeading)",
           "platformName": "\(platformName)",
           "platformIconName": "\(post.platformIcon)",
           "caption": "String (80-120 words)",
           "images": "Array {'type': 'stock', 'path': 'img_01'})"
           "hashtags": "Array (Exactly 4) [#String, #String]"
         }
        """
    
        let response = try await session.respond(to: prompt)
        
        guard let jsonString = extractAndCleanJSON(from: response.content),
              let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "EditorEngine", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to extract JSON"])
        }
        
        print("Cleaned AI JSON:\n\(jsonString)")

        return try await MainActor.run {
            try JSONDecoder().decode(EditorDraftData.self, from: data)
        }
    }
}

