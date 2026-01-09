//
//  supabase.swift
//  HandleApp
//
//  Created by SDC-USER on 08/01/26.
//

import Supabase
import Foundation

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
            supabaseKey: supabaseKey
        )
    }
    
    var currentUserID: UUID {
        // Use the actual logged-in user if available, otherwise use our Test ID
        return client.auth.currentUser?.id ?? testUserID
    }
    
    func savePreference(stepIndex: Int, selections: [String]) async {
        // 2. Use the currentUserID helper
        let data = OnboardingResponse(
            user_id: currentUserID,
            step_index: stepIndex,
            selection_tags: selections
        )

        do {
            try await client
                .from("onboarding_responses")
                .upsert(data)
                .execute()
            
            print("✅ Data successfully saved to Supabase for User: \(currentUserID)")
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
}

extension SupabaseManager {
    
    /// Fetches all 6 onboarding rows and converts them into a single UserProfile object
    func fetchUserProfile() async -> UserProfile? {
        guard let userId = client.auth.currentUser?.id else {
            print("❌ No logged-in user found.")
            return nil
        }
        
        do {
            // 1. Fetch all rows for this user from 'onboarding_responses'
            let responses: [OnboardingResponse] = try await client
                .from("onboarding_responses")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            // 2. Create a dictionary to easily find answers by step_index
            // Key = step_index (0-5), Value = selection_tags ([String])
            var answers: [Int: [String]] = [:]
            
            for response in responses {
                answers[response.step_index] = response.selection_tags
            }
            
            // 3. Map the dictionary to your UserProfile struct
            // Defaults to empty array [] if a step is missing
            return UserProfile(
                profession: answers[0] ?? [],        // Step 0
                targetAudience: answers[1] ?? [],    // Step 1
                contentGoals: answers[2] ?? [],      // Step 2
                toneOfVoice: answers[3] ?? [],       // Step 3
                contentTopics: answers[4] ?? [],     // Step 4
                preferredPlatforms: answers[5] ?? [] // Step 5
            )
            
        } catch {
            print("❌ Error assembling UserProfile: \(error)")
            return nil
        }
    }
}
