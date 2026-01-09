//
//  LLMServices.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import Foundation

class OpenRouterService {
    
    static let shared = OpenRouterService()
    
    // ⚠️ Replace with your actual OpenRouter API Key
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OpenRouterAPIKey") as? String else {
            print("⚠️ API Key not found in Info.plist")
            return ""
        }
        return key
    }
    private let apiURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    
    private init() {}
    
    func generateDraft(idea: String, profile: UserProfile, completion: @escaping (Result<EditorDraftData, Error>) -> Void) {
        
        // 1. Build the System Prompt using your profile helper
        let systemInstruction = """
        You are an expert Social Media Manager.
        
        \(profile.promptContext)
        
        TASK:
        The user has a rough idea: "\(idea)".
        Generate a high-quality post for the SINGLE best platform listed in their 'Focus Platforms'.
        
        OUTPUT FORMAT:
        Return ONLY valid JSON matching this structure:
        {
            "platformName": "String",
            "platformIconName": "String (e.g. linkedin, instagram, twitter)",
            "caption": "String (The full post content)",
            "images": ["String (Visual description of image)"],
            "hashtags": ["String"],
            "postingTimes": ["String"]
        }
        """
        
        // 2. Prepare JSON Body
        let parameters: [String: Any] = [
            "model": "openai/gpt-3.5-turbo", // or "anthropic/claude-3-haiku"
            "messages": [
                ["role": "system", "content": systemInstruction],
                ["role": "user", "content": "Generate the post now."]
            ],
            "response_format": ["type": "json_object"] // Forces valid JSON
        ]
        
        // 3. Request Setup
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // Optional OpenRouter headers
        request.addValue("YourAppName", forHTTPHeaderField: "X-Title")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        // 4. Execute
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                // Parse OpenRouter/OpenAI wrapper
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String,
                   let contentData = content.data(using: .utf8) {
                    
                    // Parse actual Draft Data
                    let draft = try JSONDecoder().decode(EditorDraftData.self, from: contentData)
                    completion(.success(draft))
                }
            } catch {
                print("Parsing Error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}
