//
//  PKCEHelper.swift
//  HandleApp
//
//  Created by Ketaki on 12/01/26.
//
import Foundation
import CryptoKit

// Proof Key for Code Exchange (PKCE) Helper 

// PKCE demands a SHA256 hashed and Base64URL-encoded version the secret cryptokit gives us the tools to perform this hashing which would otherwise have been manual

// using hashing for oauth 2.0 security 
class PKCEHelper {
    
    //Generate a random string (The "Verifier")
    static func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncodedString()
    }
    
    //Hash it to create the "Challenge"
    // Challenge hashed and Base64URL-encoded version of that secret
    static func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        let hashed = SHA256.hash(data: data)
        return Data(hashed).base64URLEncodedString()
    }
}

// Helper extension for Base64URL encoding Standard requirement for OAuth
extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
// base
