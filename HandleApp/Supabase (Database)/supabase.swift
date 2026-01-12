//
//  supabase.swift
//  HandleApp
//
//  Created by SDC-USER on 08/01/26.
//

import Supabase
import Foundation

struct SocialConnection: Codable {
    let user_id: UUID
    let platform: String
    let access_token: String
}


struct OnboardingResponse: Codable {
    let user_id: UUID
    let step_index: Int
    let selection_tags: [String]
}

class SupabaseManager {
    static let shared = SupabaseManager()
    
    private let supabaseURL = URL(string: "https://rfoqrrppblagcurghzhy.supabase.co")!
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmb3FycnBwYmxhZ2N1cmdoemh5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4MTU0MDEsImV4cCI6MjA4MzM5MTQwMX0.PiPBEpJA5XZW2u1Nbqk4mva6p8eyP_iTcclpXEk-I9k"
    
    // The main client instance
    let client: SupabaseClient
    private let testUserID = UUID(uuidString: "801e5aff-c41e-45bf-904f-bd1bc6bbcd17")!
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                            db: .init(
                                decoder: {
                                    let decoder = JSONDecoder()
                                                        // 1. USE DEFAULT KEYS (because you have CodingKeys now)
                                                        decoder.keyDecodingStrategy = .useDefaultKeys
                                                        
                                                        // 2. HANDLE SUPABASE DATES
                                                        decoder.dateDecodingStrategy = .iso8601
                                                        return decoder
                                }()
                            )
                        )
        )
    }
    
    var currentUserID: UUID {
        // Use the actual logged-in user if available, otherwise use our Test ID
        return client.auth.currentUser?.id ?? testUserID
    }
    
    func savePreference(stepIndex: Int, selections: [String]) async {
        let data = OnboardingResponse(user_id: currentUserID, step_index: stepIndex, selection_tags: selections)
        do {
            // Change: Use .database before .from
            try await client
                .from("onboarding_responses")
                .upsert(data)
                .execute()
            print("✅ Data successfully saved")
        } catch {
            print("❌ Supabase Error: \(error)")
        }
    }
    
    func fetchAllPreferences() async -> [Int: [String]] {
        guard let userId = client.auth.currentUser?.id else { return [:] }
        
        do {
            // Explicitly type the result so Supabase knows how to decode it
            let responses: [OnboardingResponse] = try await client
                .from("onboarding_responses")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value // This property handles the actual decoding
            
            var preferencesDict: [Int: [String]] = [:]
            for response in responses {
                preferencesDict[response.step_index] = response.selection_tags
            }
            return preferencesDict
            
        } catch {
            print("❌ Error fetching preferences: \(error)")
            return [:]
        }
    }
    
    // Save Social Token (Twitter/Instagram)
        func saveSocialToken(platform: String, token: String) async {
            let data = SocialConnection(
                user_id: currentUserID, // Uses your existing helper
                platform: platform,
                access_token: token
            )
            
            do {
                try await client
                    .from("social_connections")
                    .upsert(data)
                    .execute()
                
                print("✅ Saved \(platform) token to Supabase!")
            } catch {
                print("❌ Failed to save token: \(error)")
            }
        }
    
}

extension SupabaseManager {
    
    func fetchUserProfile() async -> UserProfile? {
        // 1. Use currentUserID (works for Test User or Auth User)
        let userId = currentUserID
        
        do {
            // 2. Fetch data
            let responses: [OnboardingResponse] = try await client
                .from("onboarding_responses")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            // 3. Organize by Step Index
            var answers: [Int: [String]] = [:]
            for resp in responses {
                answers[resp.step_index] = resp.selection_tags
            }
            
            // 4. Map to Struct using CORRECT indices from OnboardingDataStore
            return UserProfile(
                role: answers[0] ?? [],           // Step 0: Role (Founder/Employee)
                industry: answers[1] ?? [],       // Step 1: Industry (Tech/Finance...)
                primaryGoals: answers[2] ?? [],   // Step 2: Goals (Awareness/Leads...)
                contentFormats: answers[3] ?? [], // Step 3: Formats (Case Studies/Q&A...)
                toneOfVoice: answers[4] ?? [],    // Step 4: Tone (Witty/Direct...)
                targetAudience: answers[5] ?? []  // Step 5: Audience (Prospects/Peers...)
            )
            
        } catch {
            print("❌ Error assembling UserProfile: \(error)")
            return nil
        }
    }
}
