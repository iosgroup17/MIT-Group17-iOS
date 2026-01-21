//
//  SocialAuthManager.swift
//  HandleApp
//
//  Created by SDC_USER on 12/01/26.
//

import Foundation

class SocialAuthManager {
    static let shared = SocialAuthManager()
    // singleton design pattern to have a single instance throughout the app
      
    // TWITTER (X)
    // We use the computed property to fetch fresh from AppConfig
    private var twitterClientID: String { AppConfig.twitterClientID }
    private let twitterRedirectURI = "handleapp://callback"
    // Twitter allows for Native App Redirection using a Custom URL Scheme
   
    // INSTAGRAM
    private var instagramAppID: String { AppConfig.instagramAppID }
    private var instagramAppSecret: String { AppConfig.instagramAppSecret }
    private let instagramRedirectURI = "https://handleapp.com/auth/"
   
    // LINKEDIN
    private var linkedInClientID: String { AppConfig.linkedInClientID }
    private var linkedInClientSecret: String { AppConfig.linkedInClientSecret }
    private let linkedInRedirectURI = "https://handleapp.com/auth/"

    var currentTwitterVerifier: String?
   
    private init() {}

    // MARK: - TWITTER (X) AUTH FLOW
   
    func getTwitterAuthURL() -> String? {


        // generates a Verifier and a Challenge
        // sends challenge to twitter twitter sends a code back 
        let verifier = PKCEHelper.generateCodeVerifier()
        // Proof Key for Code Exchange (PKCE) for enhanced security
        self.currentTwitterVerifier = verifier
       
        guard let challenge = PKCEHelper.generateCodeChallenge(from: verifier) else {
            print("Failed to generate PKCE Challenge")
            return nil
        }
       
        let scope = "tweet.read users.read offline.access"
        // scopes for read access and offline access (refresh tokens)
        let state = "random_state_string"
        // antiforgery state parameter
       
        let urlString = "https://twitter.com/i/oauth2/authorize?response_type=code&client_id=\(twitterClientID)&redirect_uri=\(twitterRedirectURI)&scope=\(scope)&state=\(state)&code_challenge=\(challenge)&code_challenge_method=S256"
       

        //    converts special characters to percent-encoded format for URL
        return urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
   
    func exchangeTwitterCodeForToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {

        // send code + real verifier (secret) to get access token
        guard let url = URL(string: "https://api.twitter.com/2/oauth2/token") else { return }
        guard let verifier = currentTwitterVerifier else {
            completion(.failure(NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing PKCE Verifier"])))
            return
        }

    //    sending a post request to exchange code for access token
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "code=\(code)&grant_type=authorization_code&client_id=\(twitterClientID)&redirect_uri=\(twitterRedirectURI)&code_verifier=\(verifier)"
        request.httpBody = bodyString.data(using: .utf8)
       

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
           
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    completion(.success(accessToken))
                } else {
                    completion(.failure(NSError(domain: "TwitterAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "No token found"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()

        // Asynchronous HTTP POST Request that handles the response from the Twitter API json->swift dictionary
    }
   
    // MARK: - INSTAGRAM (GRAPH API) AUTH FLOW
   
    func getInstagramAuthURL() -> String {
        // Permissions for Business Analytics
        let scope = "instagram_basic,instagram_manage_insights,pages_show_list,pages_read_engagement"
        let state = "random_secure_string"
       
        // Uses Facebook OAuth because it's the Business API
        return "https://www.facebook.com/v17.0/dialog/oauth?client_id=\(instagramAppID)&redirect_uri=\(instagramRedirectURI)&state=\(state)&scope=\(scope)&response_type=token" // 'token' flow is simpler for client-side if supported, otherwise 'code'
    }
   
    // If using 'response_type=token' above, we don't need to exchange code.
   
    // MARK: - LINKEDIN AUTH FLOW
   
    func getLinkedInAuthURL() -> String {
            let scope = "openid profile email"
            let state = "random_linked_in_string"
           
            return "https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=\(linkedInClientID)&redirect_uri=\(linkedInRedirectURI)&state=\(state)&scope=\(scope)"
    }
   
    func exchangeLinkedInCodeForToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
            let urlString = "https://www.linkedin.com/oauth/v2/accessToken"
            guard let url = URL(string: urlString) else { return }
           
            let bodyString = "grant_type=authorization_code&code=\(code)&redirect_uri=\(linkedInRedirectURI)&client_id=\(linkedInClientID)&client_secret=\(linkedInClientSecret)"
           
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyString.data(using: .utf8)
           
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { return }
               
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let accessToken = json["access_token"] as? String {
                        completion(.success(accessToken))
                    } else {
                        completion(.failure(NSError(domain: "LinkedInAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse token"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        }
}
