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
                                                        decoder.keyDecodingStrategy = .useDefaultKeys
                                                        
                                                        // supabase dates
                                                        decoder.dateDecodingStrategy = .iso8601
                                                        return decoder
                                }()
                            )
                        )
        )
    }
    
    var currentUserID: UUID {
        //logged in user if available otherwise testUserID
        return client.auth.currentUser?.id ?? testUserID
    }
    
    
    //save what the user has selected in the onboarding and insert that into table
    func savePreference(stepIndex: Int, selections: [String]) async {
        let data = OnboardingResponse(user_id: currentUserID, step_index: stepIndex, selection_tags: selections)
        do {
            try await client
                .from("onboarding_responses")
                .upsert(data)
                .execute()
            print("Data successfully saved")
        } catch {
            print("Supabase Error: \(error)")
        }
    }
    
    
    //fetching the preferences from supabase to be used for generation by AI
    func fetchAllPreferences() async -> [Int: [String]] {
        guard let userId = client.auth.currentUser?.id else { return [:] }
        
        do {
            // tyoe results to supabase so that it decodes
            let responses: [OnboardingResponse] = try await client
                .from("onboarding_responses")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            var preferencesDict: [Int: [String]] = [:]
            for response in responses {
                preferencesDict[response.step_index] = response.selection_tags
            }
            return preferencesDict
            
        } catch {
            print("Error fetching preferences: \(error)")
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
                
                print("Saved \(platform) token to Supabase!")
            } catch {
                print("Failed to save token: \(error)")
            }
        }
    
}

extension SupabaseManager {
    
    func fetchUserProfile() async -> UserProfile? {
        let userId = currentUserID
        
        do {
            let responses: [OnboardingResponse] = try await client
                .from("onboarding_responses")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            //organize acc to index
            var answers: [Int: [String]] = [:]
            for resp in responses {
                answers[resp.step_index] = resp.selection_tags
            }
            
            // mapping data to correct indices
            return UserProfile(
                role: answers[0] ?? [],
                industry: answers[1] ?? [],
                primaryGoals: answers[2] ?? [],
                contentFormats: answers[3] ?? [],
                toneOfVoice: answers[4] ?? [],
                targetAudience: answers[5] ?? []
            )
            
        } catch {
            print("Error assembling UserProfile: \(error)")
            return nil
        }
    }
    
    func fetchLogPosts() async -> [Post] {
        do {
            let posts: [Post] = try await client
                .from("social_media_posts")
                .select()
                .execute()
                .value
                
            print("Successfully fetched \(posts.count) global posts")
            return posts
        } catch {
            print("Error fetching global posts: \(error)")
            return []
        }
    }

    // Delete a post from Supabase
    func deleteLogPost(id: String) async {
        do {
            try await client
                .from("posts")
                .delete()
                .eq("id", value: id)
                .execute()
            print("Post deleted")
        } catch {
            print("Delete error: \(error)")
        }
    }
    
    
    //load the multiple type of post idea and formats
    func loadPostsIdeas() async throws -> PostIdeasResponse {
        
        print("Fetching data from Supabase...")
        
        //fetch all tables in parallel
        async let topIdeasQuery: [TopIdea] = client.from("top_ideas").select().execute().value
        async let topicsQuery: [TrendingTopic] = client.from("trending_topics").select().execute().value
        async let recommendationsQuery: [Recommendation] = client.from("recommendations").select().execute().value
        async let postDetailsQuery: [PostDetail] = client.from("post_details").select().execute().value
        
        //fetch flat list of topic ideas (group them later)
        async let flatTopicIdeasQuery: [TopicIdea] = client.from("topic_ideas").select().execute().value

        let (topIdeas, trendingTopics, recommendations, postDetails, flatTopicIdeas) = try await (
            topIdeasQuery,
            topicsQuery,
            recommendationsQuery,
            postDetailsQuery,
            flatTopicIdeasQuery
        )
        
        // process the data (group topic ideas into sections)
        // group by topic_id
        let groupedIdeas = Dictionary(grouping: flatTopicIdeas, by: { $0.topicId })
        
        //map to TopicIdeaGroup struct
        let topicIdeaGroups = groupedIdeas.map { (key, value) in
            TopicIdeaGroup(topicId: key, ideas: value)
        }
        
        print("Data fetched successfully!")
        
        //return the combined object
        return PostIdeasResponse(
            topIdeas: topIdeas,
            trendingTopics: trendingTopics,
            topicIdeas: topicIdeaGroups,
            recommendations: recommendations,
            selectedPostDetails: postDetails
        )
    }
}
