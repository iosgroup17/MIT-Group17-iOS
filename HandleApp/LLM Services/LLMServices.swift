//
//  LLMServices.swift
//  HandleApp
//
//  Created by SDC-USER on 09/01/26.
//

import Foundation

//
//  LLMServices.swift
//  HandleApp
//
//  Updated for Gemini 1.5 Flash
//

import Foundation

class GeminiService {
    
    static let shared = GeminiService()
    
    // ⚠️ Ensure you have added "GeminiAPIKey" to your Info.plist
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String else {
            print("⚠️ Gemini API Key not found in Info.plist")
            return ""
        }
        return key
    }
    
    private init() {}
    
    func generateDraft(idea: String, profile: UserProfile, completion: @escaping (Result<EditorDraftData, Error>) -> Void) {
        
        // 1. URL for Gemini 1.5 Flash
        // We inject the API Key directly into the URL query parameter for Google's API
        let endpointString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
                
        guard let url = URL(string: endpointString) else {
            print("Invalid URL")
            return
        }

        
        // 2. Build the Prompt
        // Gemini supports a specific "system_instruction" field, which is great for your persona setup.
        let systemInstructionText = """
        You are an expert Social Media Manager.
        
        \(profile.promptContext)
        
        TASK:
        The user has a rough idea: "\(idea)".
        Generate a high-quality post for the specified platform.
        
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
        
        // 3. Construct the Request Body
        // Gemini expects 'contents' for user messages and 'system_instruction' for system prompts.
        // We also force JSON response mime type.
        let parameters: [String: Any] = [
            "system_instruction": [
                "parts": [
                    ["text": systemInstructionText]
                ]
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": "Draft a post for this idea: \(idea)"]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json" // Forces Gemini to reply in JSON
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        // 4. Execute
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            // Debug: Print raw JSON to see if errors occur
            // if let rawString = String(data: data, encoding: .utf8) { print("Raw Response: \(rawString)") }

            do {
                // 5. Parse Gemini Response Structure
                // Gemini returns: { "candidates": [ { "content": { "parts": [ { "text": "..." } ] } } ] }
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = jsonResponse["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let contentContainer = firstCandidate["content"] as? [String: Any],
                   let parts = contentContainer["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String,
                   let contentData = text.data(using: .utf8) {
                    
                    // Parse the actual Draft Data (JSON inside the text)
                    let draft = try JSONDecoder().decode(EditorDraftData.self, from: contentData)
                    completion(.success(draft))
                    
                } else {
                    // Handle API Errors (e.g., if key is wrong, Google returns an "error" object)
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorObj = jsonResponse["error"] as? [String: Any],
                       let message = errorObj["message"] as? String {
                        print("Gemini API Error: \(message)")
                    }
                    let error = NSError(domain: "GeminiService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Gemini response"])
                    completion(.failure(error))
                }
            } catch {
                print("Parsing Error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}
