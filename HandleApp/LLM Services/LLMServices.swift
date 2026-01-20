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
    
    
    func generateDraft(idea: String, profile: UserProfile, completion: @escaping (Result<EditorDraftData, Error>) -> Void) {

        let endpointString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
       
        guard let url = URL(string: endpointString) else {
            print("Invalid URL")
            return
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
            "platformIconName": "String (use 'icon-linkedin', 'icon-instagram', 'icon-twitter', or 'doc.text' for strategy)",
            "caption": "String (The post content OR the answer to the user's question)",
            "images": ["String (Visual description of image), or image-1, img_01, img-post-1"],
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
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
           
            guard let data = data else { return }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = jsonResponse["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let contentContainer = firstCandidate["content"] as? [String: Any],
                   let parts = contentContainer["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String,
                   let contentData = text.data(using: .utf8) {
                   
                    let draft = try JSONDecoder().decode(EditorDraftData.self, from: contentData)
                    DispatchQueue.main.async {
                        completion(.success(draft))
                    }
                   
                } else {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorObj = json["error"] as? [String: Any],
                       let msg = errorObj["message"] as? String {
                        print("Gemini API Error: \(msg)")
                    }
                    throw NSError(domain: "GeminiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Gemini response"])
                }
            } catch {
                print("Parsing Error: \(error)")
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}
