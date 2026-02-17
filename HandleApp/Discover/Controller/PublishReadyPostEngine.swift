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
    private var session: LanguageModelSession?
    
    private init() {}
    
    private func ensureSession() async throws -> LanguageModelSession {
        if let existing = session { return existing }
        let newSession = LanguageModelSession(model: SystemLanguageModel.default)
        self.session = newSession
        return newSession
    }
    
    // MARK: - GENERATE LIST OF IDEAS
    func generatePublishReadyPosts(trendText: String, context: UserProfile) async throws -> [PublishReadyPost] {
        let session = try await ensureSession()
        
        let prompt = """
                You are a world-class social media strategist for a:
                \(context.professionalIdentity.joined(separator: ", "))
                
                DEEP CONTEXT:
                - Industry: \(context.industry.joined(separator: ", "))
                - Current Focus: \(context.currentFocus.joined(separator: ", ")) (Tailor posts to this specific focus)
                - Target Audience: \(context.targetAudience.joined(separator: ", "))
                - Main Goal: \(context.primaryGoals.joined(separator: ", "))
                - Voice/Style: \(context.contentFormats.joined(separator: ", "))
                
                
                TASK:
                Generate 6 DISTINCT, high-impact content ideas using the following 6 specific angles (Do not repeat angles):
                
                1. The Contrarian (Go against common industry advice regarding the trend).
                2. The "How-To" (Actionable, step-by-step utility).
                3. The Personal Insight (A lesson learned or mistake made).
                4. The Future Prediction (Where is this trend going in 6 months?).
                5. The Behind-the-Scenes (How you/your company handles this trend).
                6. The Resource/Tool (A specific tool or hack related to the trend).
                
                DISTRIBUTION RULES:
                - Mix the platforms: Generate specifically for "icon-linkedin", "icon-x", and "icon-instagram".
                - Do not put all ideas on one platform.
                
                OUTPUT CONSTRAINTS:
                1. Return ONLY raw JSON. No markdown.
                2. "post_heading": Punchy, click-worthy hooks (Max 25 chars).
                3. "platform_icon": "icon-x", "icon-instagram", or "icon-linkedin".
                4. "caption": 80-100 chars. Conversational teaser. NO hashtags here.
                5. "hashtags": Exactly 3 relevant tags.
                6. "prediction_text": One sentence, 10 characters explaining WHY this angle works.
                
                7. IMAGES ("post_image"):
                   - Library: ["img_01" ... "img_34"]
                   - FOR INSTAGRAM: You MUST always include 1 image from the library.
                   - FOR X (TWITTER) & LINKEDIN: Prefer text-only posts. Only add an image if absolutely necessary. If text-only, omit this field or return null.
                
                You MUST wrap the array of objects inside a root JSON object with the key "posts".

                REQUIRED JSON STRUCTURE:
                {
                  "posts": [
                    {
                      "post_heading": "Headline",
                      "platform_icon": "icon-linkedin",
                      "post_image": ["img_01"], 
                      "caption": "Post text body goes here without tags",
                      "hashtags": ["#tag1", "#tag2"],
                      "prediction_text": "Why this works"
                    }
                  ]
                }

                IMPORTANT: Start your response immediately with { "posts": [
                """
        
        let response = try await session.respond(to: prompt)

        guard let jsonString = extractAndCleanJSON(from: response.content) else {
            print("AI Output was not valid JSON:\n\(response.content)")
            throw NSError(domain: "Decoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "AI Output extraction failed"])
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
        let session = try await ensureSession()
        
        let platformName = post.platformIcon.contains("linkedin") ? "LinkedIn" : (post.platformIcon.contains("instagram") ? "Instagram" : "X (Twitter)")
        
        let originalHeading = post.postHeading
        
        let prompt = """
        ACT AS: Expert Social Media Copywriter.
        
        CONTEXT:
        - Platform: \(platformName)
        - Audience: \(context.targetAudience.joined(separator: ", "))
        - Goal: \(context.primaryGoals.joined(separator: ", "))
        
        INPUT IDEA:
        - Hook: "\(post.postHeading)"
        - Draft: "\(post.caption)"
        
        TASK:
        Expand this idea into a final publish-ready draft.
        
        STRICT REQUIREMENTS:
                1. Caption (Creative Expansion): 
                   - Elaborate on the "Draft" input. 
                   - Write a creative, engaging, value-packed caption (approx 100-120 words). 
                   - Use storytelling, line breaks, and emojis. 
                   - CRITICAL: DO NOT put hashtags in this field.
                   
                2. Visuals (Select from List): 
                   - You have access to a stock library with IDs: ["img_01", "img_02", "img_03", "img_04", "img_05", "img_06", "img_07", "img_08", "img_09", "img_10", "img_11", "img_12", "img_13", "img_14", "img_15", "img_16".....till "img_34"].
                   - Select 2-3 specific Image IDs from this list that best match the mood of the post.
                   
                3. Hashtags(STRICT CONSTARINTS): 
                   - Generate exactly 4 hashtags.
                   - CONSTRAINT: Max length 12 characters per tag.
                   - CONSTRAINT: No single words (e.g. use "#TechTips" NOT "#Tech").
                   - CONSTRAINT: No generic tags like "#FYP" or "#Viral".
                   - Must be relevant to: \(context.industry.joined(separator: ", ")).
                   
                4. Posting Times (Strategic Analysis): 
                   - Analyze when the specific Target Audience ("\(context.targetAudience.joined(separator: ", "))") is most active on \(platformName).
                   - Suggest 2 specific, optimal times (e.g., "Sunday at [Time]", "Thursday at [Time]"). 
                   - Do NOT use generic 9 AM defaults unless strictly appropriate.
        
                5. Post Heading (Consistency):
                   - You MUST include the "post_heading" key.
                   - The value MUST be exactly: "\(originalHeading)".
                   - Do not rewrite or alter the hook.
                
                OUTPUT JSON (Strictly match this schema):
                {
                    "post_heading": "\(originalHeading)",
                    "platformName": "\(platformName)",
                    "platformIconName": "\(post.platformIcon)",
                    "caption": "The elaborated, creative caption body goes here...",
                    "images": ["img_01", "img_05"],
                    "hashtags": ["#specific", "#industry", "#tags"],
                    "postingTimes": ["[Day] at [Optimal Time]", "[Day] at [Optimal Time]"]
                }
        """
        let response = try await session.respond(to: prompt)
        
        guard let jsonString = extractAndCleanJSON(from: response.content),
              let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "EditorEngine", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to extract JSON"])
        }
        
        print("Cleaned AI JSON:\n\(jsonString)")

        var draft = try JSONDecoder().decode(EditorDraftData.self, from: data)
        
        return draft
    }
}
