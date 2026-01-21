//
//  LLMServices.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//



import Foundation

class GeminiService {
    
    static let shared = GeminiService()
    
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String, !key.isEmpty else {
            print("Gemini API Key not found. Check Secrets.xcconfig and Info.plist.")
            return ""
        }
        if key.contains("$(") {
            print("API Key variable not substituted. Ensure 'Secrets.xcconfig' is set in Project > Info > Configurations.")
            return ""
        }
        return key
    }
    
    private init() {}
    
    
    func generateDraft(idea: String, profile: UserProfile) async throws -> EditorDraftData {
        let endpointString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        
        guard let url = URL(string: endpointString) else {
            throw URLError(.badURL)
        }

        let systemInstructionText = """
        You are an expert Social Media Manager and Strategist.
        
        \(profile.promptContext)
        
        TASK:
        Analyze the "User Request" below. It will be one of three things:
            1. A NEW POST IDEA (e.g., "Write a post about coffee").
                -> Action: Generate a high-quality post for the most suitable platform.
        
            2. A MODIFICATION request (e.g., "Make it shorter", "Add more emojis").
                -> Action: Rewrite the previous concept (or generate a new one) applying these specific changes.
        
            3. A STRATEGY QUESTION (e.g., "What images should I use?", "When should I post?").
                -> Action: Provide your expert advice.
                - Put your answer inside the "caption" field.
                - Set "platformName" to "Strategy".
                - Fill "images" or "hashtags" only if relevant to the advice.

        OUTPUT FORMAT:
        You MUST return ONLY valid JSON. Do not add markdown blocks like ```json.
        Structure:
        {
            "platformName": "String (e.g., LinkedIn, Instagram, or 'Strategy' if answering a question)",
            "platformIconName": "String (use 'linkedin', 'instagram', 'twitter', or 'doc.text' for strategy)",
            "caption": "String (The post content OR the answer to the user's question)",
            "images": ["String (Visual description of image)"],
            "hashtags": ["String"],
            "postingTimes": ["String"]
        }
        """

        let parameters: [String: Any] = [
            "system_instruction": [
                "parts": [ ["text": systemInstructionText] ]
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [ ["text": "User Request: \(idea)"] ]
                ]
            ],
            "generation_config": [
                "response_mime_type": "application/json"
            ]
        ]
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)

        
        let (data, response) = try await URLSession.shared.data(for: request)

        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = json["error"] as? [String: Any],
               let msg = errorObj["message"] as? String {
                print("Gemini API Error: \(msg)")
            }
            throw NSError(domain: "GeminiService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned error code: \(httpResponse.statusCode)"])
        }


        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = jsonResponse["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let contentContainer = firstCandidate["content"] as? [String: Any],
              let parts = contentContainer["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String,
              let contentData = text.data(using: .utf8) else {
            
            throw NSError(domain: "GeminiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Gemini response structure"])
        }


        let draft = try JSONDecoder().decode(EditorDraftData.self, from: contentData)
        
        return draft
    }
}
