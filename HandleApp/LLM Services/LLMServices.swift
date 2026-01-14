import Foundation

class GeminiService {
    
    static let shared = GeminiService()
    
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String else {
            print("⚠️ Gemini API Key not found in Info.plist")
            return ""
        }
        // DEBUG: Uncomment the line below to verify if your key is resolving correctly
         print("DEBUG: API Key being used: [\(key)]")
        return key
    }
    
    private init() {}
    
    func generateDraft(idea: String, profile: UserProfile, completion: @escaping (Result<EditorDraftData, Error>) -> Void) {
        
        // 1. URL for Gemini 2.0 Flash (Standard Endpoint)
        let endpointString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
                
        guard let url = URL(string: endpointString) else {
            print("Invalid URL")
            return
        }

        let systemInstructionText = """
        You are an expert Social Media Manager.
        \(profile.promptContext)
        TASK: The user has a rough idea: "\(idea)". Generate a high-quality post.
        OUTPUT FORMAT: Return ONLY valid JSON matching the EditorDraftData structure.
        """
        
        let parameters: [String: Any] = [
            "system_instruction": ["parts": [["text": systemInstructionText]]],
            "contents": [["role": "user", "parts": [["text": "Draft a post for: \(idea)"]]]],
            "generationConfig": ["response_mime_type": "application/json"]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 2. The Critical Fix: Pass the API Key in the Header instead of the URL
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // 3. Check for Transport Errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // 4. Check HTTP Status & Handle Detailed Errors
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("⚠️ Gemini API Server Error (\(httpResponse.statusCode))")
                if let data = data, let errorMsg = String(data: data, encoding: .utf8) {
                    print("Detailed Error Details: \(errorMsg)")
                }
                let statusError = NSError(domain: "GeminiService", code: httpResponse.statusCode,
                                          userInfo: [NSLocalizedDescriptionKey: "Server returned status \(httpResponse.statusCode)"])
                completion(.failure(statusError))
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
                    completion(.success(draft))
                } else {
                    throw NSError(domain: "GeminiService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unexpected JSON structure"])
                }
            } catch {
                print("Parsing Error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}
