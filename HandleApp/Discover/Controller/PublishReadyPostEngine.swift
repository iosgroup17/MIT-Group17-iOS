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
 
    func generatePublishReadyPosts(context: UserProfile) async throws -> [PublishReadyPost] {
        let session = try await ensureSession()
        
        let prompt = """
                You are a world-class social media strategist for:
                \(context.professionalIdentity.joined(separator: ", "))

                PAST SUCCESSES: 

                CONTEXT:
                Industry: \(context.industry.joined(separator: ", "))
                Focus: \(context.currentFocus.joined(separator: ", "))
                Audience: \(context.targetAudience.joined(separator: ", "))
                Goals: \(context.primaryGoals.joined(separator: ", "))
                Voice: \(context.contentFormats.joined(separator: ", "))

                LEGAL (India 2026 AI Rules):
                - NO false claims/unverified stats
                - NO medical/financial advice
                - Add "AI-assisted" disclosure if required
                - NO deepfakes/illegal promotion

                QUALITY:
                - Founder voice: Authentic, no buzzwords
                - 100% utility: 1 clear takeaway/post
                - Hooks: First 5 words = attention grab

                TASK: 6 DISTINCT posts, EXACT angles (1 each):
                1. Contrarian: Challenge industry myth
                2. How-To: 3-step actionable
                3. Personal: Your real lesson
                4. Prediction: 6-month forecast  
                5. Behind-Scenes: Your process
                6. Tool: Specific hack + results

                PLATFORM MIX: 2x each "icon-linkedin", "icon-x", "icon-instagram"

                {

                "posts": [

                {
                  "post_heading": "Hook ≤20 chars",
                  "platform_icon": "icon-linkedin"|"icon-x"|"icon-instagram",
                  "post_image": Instagram=["img_XX"], others=null,
                  "caption": "Publish-ready. Instagram:≤125chars, X:≤240, LinkedIn:≤250. No hashtags.",
                  "hashtags": ["#Tag1","#Tag2","#Tag3"],
                  "prediction_text": "Why it converts"  //<= 80 chars
                }

                ]
                } STRICT OUTPUT CONSTRAINTS - VIOLATION = FAIL 
                READ TWICE BEFORE WRITING:

                1. ONLY raw JSON. ZERO markdown, explanations, or extra text.
                2. post_heading: EXACTLY ≤25 chars. Count: "Punchy hook here" = 15 chars.
                3. platform_icon: ONLY "icon-x", "icon-instagram", or "icon-linkedin". No others.
                4. caption: EXACTLY 150-200 chars (spaces count). Teaser only. ZERO hashtags.
                5. hashtags: EXACTLY 3 tags: ["#Tag1","#Tag2","#Tag3"]
                6. prediction_text: EXACTLY 1 sentence ≤100 chars explaining WHY angle works.

                7. post_image RULES (MANDATORY):
                   - Instagram: ALWAYS 1 image: ["img_01"] to ["img_34"]
                   - X & LinkedIn: null OR omit if text-only (PREFER null)
                   - Library ONLY: img_01-img_34. Match industry.

                JSON CHECKLIST (Follow exactly):
                - Root: {"posts": [array of 6]}
                - 6 posts TOTAL. No more, no less.
                - Platforms: Mix 2 each icon-x, icon-instagram, icon-linkedin

                EXAMPLE (Copy this format):
                {
                  "posts": [
                    {
                      "post_heading": "Stop this now",
                      "platform_icon": "icon-x",
                      "post_image": null,
                      "caption": "200 chars teaser here exactly. Actionable insight for founders. Clear CTA ends it.",
                      "hashtags": ["#FounderTips","#Growth","#SaaS"],
                      "prediction_text": "Contrarian sparks debate (32 chars)"
                    },
                    {
                      "post_heading": "3-step hack",
                      "platform_icon": "icon-instagram", 
                      "post_image": ["img_15"],
                      "caption": "Instagram visual caption 150-200 chars exactly...",
                      "hashtags": ["#HowTo","#Startup","#Marketing"],
                      "prediction_text": "Actionable = shares"
                    }
                  ]
                }

                START YOUR RESPONSE NOW: {"posts": [
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
    func generateTrendingTopicPosts(topic: TrendingTopic, context: UserProfile) async throws -> [PublishReadyPost] {
        let session = try await ensureSession()
        
        let prompt = """
     TRENDING TOPIC POST GENERATOR 🚨
    READ TWICE. FOLLOW EVERY CONSTRAINT EXACTLY.

    TRENDING TOPIC (EMPHASIZE IN ALL POSTS):
     \(topic.topicName)
    \(topic.shortDescription)
    WHY HOT NOW: \(topic.trendingContext)
    CATEGORY: \(topic.category)
    Hashtags: \(topic.hashtags.joined(separator: ", "))

    USER:
    \(context.professionalIdentity.joined(separator: ", "))
    \(context.industry.joined(separator: ", "))
    \(context.targetAudience.joined(separator: ", "))

     STRICT OUTPUT CONSTRAINTS - VIOLATION = FAIL 
    ALL 4 POSTS BASED ONLY ON THIS SPECIFIC TOPIC:

    1. ONLY raw JSON. ZERO markdown, explanations, or extra text.
    2. post_heading: EXACTLY ≤25 chars. MUST reference "\(topic.topicName)"
    3. platform_icon: ONLY "icon-x", "icon-instagram", or "icon-linkedin"
    4. caption: EXACTLY 80-100 chars (spaces count). Teaser only. ZERO hashtags. 
    5. hashtags: EXACTLY 3 tags FROM \(topic.hashtags)
    6. prediction_text: EXACTLY 1 sentence ≤100 chars explaining WHY angle works.

    7. post_image RULES (MANDATORY):
       - Instagram: ALWAYS 1 image: ["img_01"] to ["img_34"]
       - X & LinkedIn: null OR omit if text-only (PREFER null)
       - Library ONLY: img_01-img_34. Match \(context.industry.joined(separator: ", "))

    JSON CHECKLIST (Follow exactly):
    - Root: {"posts": [array of EXACTLY 4]}
    - 4 posts TOTAL. Platforms: 1x each + 1 wildcard
    - EVERY caption mentions "\(topic.topicName)" + \(topic.trendingContext) insight

    4 POST TYPES FOR THIS TOPIC ONLY:
     Contrarian take on \(topic.topicName)
     How-to using \(topic.topicName)
     Personal story with \(topic.topicName)
     Prediction about \(topic.topicName)

    EXAMPLE (Copy this format):
    {
     "posts": [
       {
         "post_heading": "\(topic.topicName) myth",
         "platform_icon": "icon-x",
         "post_image": null,
         "caption": "80 chars teaser here exactly about \(topic.topicName). Actionable insight from \(topic.trendingContext). Clear CTA.",
         "hashtags": ["\(topic.hashtags[0])","#Growth","#SaaS"],
         "prediction_text": "Trend timing = 5x engagement (24 chars)"
       }
     ]
    }

    START YOUR RESPONSE NOW: {"posts": [
        {
          "post_heading": "\(topic.topicName) exposed",
          "platform_icon": "icon-x",
          "post_image": null,
          "caption": "",
          "hashtags": ["\(topic.hashtags[0])","\(topic.hashtags[1])","\(topic.hashtags[2])"],
          "prediction_text": ""
        }
    """
        
        let response = try await session.respond(to: prompt)
        
        guard let jsonString = extractAndCleanJSON(from: response.content) else {
            print("🚨 Trending Topic JSON failed:\n\(response.content)")
            throw NSError(domain: "TrendPostGen", code: 0, userInfo: [NSLocalizedDescriptionKey: "JSON extraction failed"])
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
