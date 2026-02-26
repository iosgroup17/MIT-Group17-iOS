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
                ### SYSTEM
                    Role: World-Class Social Strategist.
                    CONTEXT: \(await context.promptContext)

                    ### DIRECTIVES (India IT Rules 2026)
                    - No false claims, medical advice, or deepfakes.
                    - Tone: Authentic founder voice. High utility. 

                    ### TASK
                    Generate 6 distinct posts (Contrarian, How-To, Personal, Prediction, Behind-Scenes, Tool).
                    Format: RAW JSON only. Mix: 2x icon-linkedin, 2x icon-x, 2x icon-instagram.

                    ### SCHEMA
                    {
                      "posts": [
                        {
                          "post_heading": "String (Max 20 chars)",
                          "platform_icon": "Enum ('icon-linkedin', 'icon-x', 'icon-instagram')",
                          "caption": "String (80-100 chars teaser)",
                          "hashtags": "Array (Exactly 3)",
                          "prediction_text": "String (Max 40 chars)",
                          "post_image": "Array/Null (Insta: ['img_01'-'img_34'], others: null)"
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
        
        let platformName = post.platformIcon.contains("linkedin") ? "LinkedIn" : (post.platformIcon.contains("instagram") ? "Instagram" : "X (Twitter)")
        
        
        let prompt = """
         ### ROLE
         Expert Social Media Elite Writer for Founders.
         CONTEXT: \(await context.promptContext)

         ### INPUT DRAFT
         - Platform: \(platformName)
         - Heading: "\(post.postHeading)"
         - Concept: "\(post.caption)"

         ### MANDATORY GUIDELINES
         1. Voice: Human, authoritative, experience-led. NO AI-isms (Unleash, Delve, Tapestry, Revolutionize).
         2. Legal (India 2026): No false claims, unverified stats, or medical/financial advice.
         3. Content: Expand draft to 150-180 words. High "Alpha" with line breaks.

         ### UI CONSTRAINTS (Strict)
         - Caption: 100-120 words. ZERO hashtags. Max 3 emojis.
         - Images: 2-3 IDs from [img_01 to img_34].
         - Hashtags: 4 compound tags (e.g. #TechTips), ≤12 chars each.
         - Times: 2 specific "[Day] at [Time]" optimized for \(platformName).

         ### OUTPUT SCHEMA (JSON Only)
         {
           "post_heading": "\(post.postHeading)",
           "platformName": "\(platformName)",
           "platformIconName": "\(post.platformIcon)",
           "caption": "String (100-120 words)",
           "images": ["img_XX", "img_XX"],
           "hashtags": "Array (Exactly 4)",
           "postingTimes": ["Day at Time", "Day at Time"]
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

extension OnDevicePostEngine {
    func generateTrendingTopicPosts(topic: TrendingTopic, context: UserProfile) async throws -> [PublishReadyPost] {
        let session = createFreshSession()
        
        let prompt = """
     ### ROLE: Elite Writer
     CTX: \(await context.promptContext)

     ### TOPIC DATA
     TRND: \(topic.topicName)
     DESC: \(topic.shortDescription)
     HOT_WHY: \(topic.trendingContext)
     CAT: \(topic.category)
     TAGS: \(topic.hashtags.joined(separator: ","))

     ### TASK
     Gen EXACTLY 4 posts for \(topic.topicName). 
     Angles: 1.Contrarian 2.How-To 3.Personal 4.Prediction.
     Mix: 1x LinkedIn, 1x X, 1x Instagram, 1x Wildcard.

     ### RULES
     1. post_heading: Max 25 chars. Must include "\(topic.topicName)".
     2. Caption: 80-100 chars teaser. 0 hashtags. Mention \(topic.topicName).
     3. post_image: Insta: ["img_01"-"img_34"]. Others: null.
     4. Tags: Exactly 3 from the TOPIC DATA TAGS above.

     ### SCHEMA (JSON Only)
     {
       "posts": [
         {
           "post_heading": "String",
           "platform_icon": "Enum('icon-linkedin', 'icon-x', 'icon-instagram')",
           "post_image": ["img_XX"],
           "caption": "80-100 chars teaser",
           "hashtags": ["#Tag1", "#Tag2", "#Tag3"],
           "prediction_text": "1 sentence (Max 100 chars) why this works"
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
            throw NSError(domain: "TrendPostGen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Data conversion failed"])
        }
        
        print("📈 TRENDING POSTS JSON:\n\(jsonString)")
        
        struct PostWrapper: Codable {
            let posts: [PublishReadyPost]
        }
        
        let decoded = try JSONDecoder().decode(PostWrapper.self, from: data)
        return decoded.posts
    }

}
