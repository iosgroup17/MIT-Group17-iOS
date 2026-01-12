//
//  SocialAuthManager.swift
//  HandleApp
//
//  Created by SDC_USER on 12/01/26.
//

import Foundation

// MARK: - INSTAGRAM (GRAPH API) KEYS


class SocialAuthManager {
    static let shared = SocialAuthManager()
    
    // ======================================================
    // MARK: - CONFIGURATION
    // ======================================================
    
    // TWITTER (X) KEYS
    // ⚠️ REPLACE THIS with the "Client ID" from your Dashboard (Under 'Keys and Tokens' -> 'OAuth 2.0 Client ID')
    private let twitterClientID = "S2F0c1FjY2hETDVZX2FDaEVuQnU6MTpjaQ"
    private let twitterRedirectURI = "handleapp://callback"
    
    // INSTAGRAM KEYS (We will fill these later)
    private let instagramAppID = "1657473478567357"
    private let instagramAppSecret = "a895f2b18829dc14820e6a20bed033ac"
    private let instagramRedirectURI = "https://handleapp.com/auth/"
    
    // Internal variable to hold the secret security code
    var currentTwitterVerifier: String?
    
    private init() {}

    // ======================================================
    // MARK: - TWITTER (X) AUTH FLOW
    // ======================================================
    
    /// Generates the secure Login URL for Twitter
    func getTwitterAuthURL() -> String? {
        // 1. Generate the security keys using your PKCEHelper
        let verifier = PKCEHelper.generateCodeVerifier()
        self.currentTwitterVerifier = verifier // SAVE THIS! We need it to prove identity later.
        
        // 2. Hash the verifier
        guard let challenge = PKCEHelper.generateCodeChallenge(from: verifier) else {
            print("❌ Failed to generate PKCE Challenge")
            return nil
        }
        
        // 3. Define what we want to access (Scopes)
        // tweet.read -> View posts
        // users.read -> View profile info (handle, profile pic)
        // offline.access -> Get a refresh token so user stays logged in
        let scope = "tweet.read users.read offline.access"
        let state = "random_state_string" // In production, make this random
        
        // 4. Build the final URL
        // We use "S256" because that is the standard encryption method for Twitter
        let urlString = "https://twitter.com/i/oauth2/authorize?response_type=code&client_id=\(twitterClientID)&redirect_uri=\(twitterRedirectURI)&scope=\(scope)&state=\(state)&code_challenge=\(challenge)&code_challenge_method=S256"
        
        return urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    /// Exchanges the "Code" we got from the callback for a real "Access Token"
    func exchangeTwitterCodeForToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let url = URL(string: "https://api.twitter.com/2/oauth2/token") else { return }
        
        // Retrieve the secret verifier we saved earlier
        guard let verifier = currentTwitterVerifier else {
            print("❌ Error: Missing PKCE Verifier. Did the app restart?")
            completion(.failure(NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing PKCE Verifier"])))
            return
        }

        // 1. Build the POST Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 2. Create the Body Data
        // Notice: We do NOT send a Client Secret here. That is correct for "Native Apps".
        let bodyString = "code=\(code)&grant_type=authorization_code&client_id=\(twitterClientID)&redirect_uri=\(twitterRedirectURI)&code_verifier=\(verifier)"
        
        request.httpBody = bodyString.data(using: .utf8)
        
        print("🔵 Exchanging Code for Token...")
        
        // 3. Send Request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // 4. Debug Print (See exactly what Twitter sends back)
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔵 Twitter Raw Response: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    
                    if let accessToken = json["access_token"] as? String {
                        // 🎉 SUCCESS!
                        completion(.success(accessToken))
                    } else {
                        // Handle specific API errors
                        let errorMsg = json["error_description"] as? String ?? "Unknown API Error"
                        completion(.failure(NSError(domain: "TwitterAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // ======================================================
    // MARK: - INSTAGRAM AUTH FLOW (Placeholders)
    // ======================================================
    
    func getInstagramAuthURL() -> String {
        // We ask for pages permissions because the Graph API treats Instagram as a "Page"
            let scope = "instagram_basic,instagram_manage_insights,pages_show_list,pages_read_engagement"
            let state = "random_secure_string"

            return "https://www.facebook.com/v17.0/dialog/oauth?client_id=\(instagramAppID)&redirect_uri=\(instagramRedirectURI)&state=\(state)&scope=\(scope)&response_type=token"
    }
    
    func exchangeInstagramCodeForToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = "https://api.instagram.com/oauth/access_token"
        guard let url = URL(string: urlString) else { return }
        
        let bodyString = "client_id=\(instagramAppID)&client_secret=\(instagramAppSecret)&grant_type=authorization_code&redirect_uri=\(instagramRedirectURI)&code=\(code)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    completion(.success(accessToken))
                } else {
                    completion(.failure(NSError(domain: "InstaAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse token"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
