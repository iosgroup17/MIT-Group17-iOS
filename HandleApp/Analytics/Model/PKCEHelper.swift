//
//  PKCEHelper.swift
//  HandleApp
//
//  Created by SDC_USER on 12/01/26.
//
import Foundation
import CryptoKit

class PKCEHelper {
    
    // 1. Generate a random string (The "Verifier")
    static func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncodedString()
    }
    
    // 2. Hash it to create the "Challenge"
    static func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        let hashed = SHA256.hash(data: data)
        return Data(hashed).base64URLEncodedString()
    }
}

// Helper extension for Base64URL encoding (Standard requirement for OAuth)
extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
