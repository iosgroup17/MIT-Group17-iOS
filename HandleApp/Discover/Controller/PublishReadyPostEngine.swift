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
         EDITOR SUITE - STRICT COMPLIANCE REQUIRED 
        You are an Expert Social Media Ghostwriter for High-Profile Founders. FOLLOW EVERY RULE EXACTLY.

        CONTEXT:
        Platform: \(platformName)
        Audience: \(context.targetAudience.joined(separator: ", "))
        Goal: \(context.primaryGoals.joined(separator: ", "))
        Industry: \(context.industry.joined(separator: ", "))

        INPUT IDEA:
        Hook: "\(post.postHeading)"
        Draft: "\(post.caption)"

         BRAND VOICE & COMMUNITY GUIDELINES (MANDATORY):
        - VOICE: Human, authoritative, and experience-led.
        - NO AI-isms: Strictly avoid "Unleash," "Delve," "Tapestry," "Revolutionize," "In today's fast-paced world."
        - VALUE: Every caption must provide a specific "Alpha" or "So-what" for the reader.
        - NO SPAM: Do not use excessive exclamation marks or "Brospeak" marketing tropes.

         INDIA IT RULES 2026 - MANDATORY (Effective Feb 20, 2026):
        - NO false claims, unverified stats, or guarantees.
        - NO medical/health/financial advice unless qualified.
        - NO deepfakes, CSAM, explosives, or illegal content.
        - ALL images = "AI-assisted stock images" (embedded metadata compliant).
        - 3-hour takedown ready: no harmful synthetic content.

         UI CONSTRAINTS (VIOLATION = APP CRASH):
        1. Caption: EXACTLY 100-120 words. Storytelling + emojis + line breaks. ZERO hashtags.
        2. Images: EXACTLY 2-3 from ["img_01", "img_02", ..., "img_34"]. Match post mood.
        3. Hashtags: EXACTLY 4 tags. ≤12 chars each. NO single words (#TechTips NOT #Tech). NO #FYP/#Viral. Industry-specific.
        4. Posting Times: EXACTLY 2 specific "[Day] at [Time]" for \(context.targetAudience.joined(separator: ", ")) on \(platformName).
        5. post_heading: MUST BE IDENTICAL: "\(originalHeading)" ZERO changes

        CHECKLIST (VERIFY BEFORE OUTPUT):
         Caption: 100-120 words (Verify count)
         Images: 2-3 valid IDs from img_01-img_34
         Hashtags: exactly 4, ≤12 chars, compound, relevant
         Times: 2 specific audience-optimized
         Heading: exactly "\(originalHeading)"
         JSON: perfect schema, no extra fields

        OUTPUT JSON (Strictly adhere to this structure):
        {
          "post_heading": "\(originalHeading)",
          "platformName": "\(platformName)",
          "platformIconName": "\(post.platformIcon)",
          "caption": "[100-120 word expansion with storytelling, max 2-3 professional emojis, and clear line breaks]",
          "images": ["img_XX", "img_XX"],
          "hashtags": ["#TagOne","#TagTwo","#TagThree","#TagFour"],
          "postingTimes": ["Day at Time", "Day at Time"]
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

extension OnDevicePostEngine {

    /// Generates trending topics based on the user's industry and audience context
    func generateTrendingTopics(context: UserProfile) async throws -> [TrendingTopic] {
        let session = try await ensureSession()
        
        let prompt = """
        ACT AS: Senior Market Trend Analyst & Social Media Strategist.
        
        CONTEXT:
        - User Professional Identity: \(context.professionalIdentity.joined(separator: ", "))
        - Industry: \(context.industry.joined(separator: ", "))
        - Target Audience: \(context.targetAudience.joined(separator: ", "))
        - Primary Goals: \(context.primaryGoals.joined(separator: ", "))
        
        TASK:
        Identify 5 emerging or evergreen "Trending Topics" specifically relevant to this user's industry and audience right now. These should be topics that would perform well on social media.
        
        FIELD REQUIREMENTS (Based on Schema):
        1. "topic_name": Short, punchy title (Max 4 words).
        2. "short_description": A clear, 1-sentence explanation of what this trend is.
        3. "category": A broad classification (e.g., "Technology", "Mindset", "Strategy", "News").
        4. "trending_context": deeply specific insight on WHY this is relevant right now (e.g., "With the rise of X, this topic is gaining traction because...").
        5. "platform_icon": Choose the BEST platform for this specific trend. Must be exactly one of: "icon-linkedin", "icon-x", "icon-instagram".
        6. "hashtags": Array of 3 relevant, high-volume hashtags.
        
        OUTPUT CONSTRAINTS:
        - Return ONLY raw JSON.
        - No markdown formatting (no ```json).
        - Must be a valid JSON object with a root key "topics".
        
        REQUIRED JSON STRUCTURE:
        {
          "topics": [
            {
              "topic_name": "Sustainable AI",
              "short_description": "Exploring the environmental impact of large language models.",
              "category": "Technology",
              "trending_context": "As AI scales, scrutiny on energy consumption is hitting mainstream media, making this a hot debate topic.",
              "platform_icon": "icon-linkedin",
              "hashtags": ["#GreenTech", "#AI", "#Sustainability"]
            }
          ]
        }
        """

        let response = try await session.respond(to: prompt)
        
        // 1. Clean JSON
        guard let jsonString = extractAndCleanJSON(from: response.content) else {
            print("🚨 AI Output was not valid JSON:\n\(response.content)")
            throw NSError(domain: "TopicGen", code: 0, userInfo: [NSLocalizedDescriptionKey: "AI Output extraction failed"])
        }
        
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "TopicGen", code: 1, userInfo: [NSLocalizedDescriptionKey: "String to Data conversion failed"])
        }
        
        print("📊 Generated Trends JSON:\n\(jsonString)")
        
        // 2. Decode
        do {
            // Helper struct to unwrap the root "topics" key
            struct TopicWrapper: Codable {
                let topics: [TrendingTopic]
            }
            
            // NOTE: Ensure your TrendingTopic struct in the main app is Codable
            // and has keys matching the JSON (snake_case) or uses CodingKeys.
            let decoded = try JSONDecoder().decode(TopicWrapper.self, from: data)
            return decoded.topics
            
        } catch {
            print("❌ Decoding Error: \(error)")
            print("❌ Offending JSON: \(jsonString)")
            throw error
        }
    }
}
