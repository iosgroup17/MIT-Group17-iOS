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
    
    func fetchConnectedPlatforms() async -> [String] {
        do {
            let connections: [SocialConnection] = try await client
                .from("social_connections")
                .select()
                .eq("user_id", value: currentUserID)
                .execute()
                .value
            
            return connections.map { $0.platform.lowercased() }
        } catch {
            return [] // If it fails, just return an empty list
        }
    }
    
    // Save Social Token (Twitter/Instagram)
        func saveSocialToken(platform: String, token: String) async {
            let data = SocialConnection(
                user_id: currentUserID, 
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
                professionalIdentity: answers[0] ?? [], // Step 0: Identity
                currentFocus: answers[1] ?? [],         // Step 1: Working on
                industry: answers[2] ?? [],             // Step 2: Domain/Industry
                primaryGoals: answers[3] ?? [],         // Step 3: Goals
                contentFormats: answers[4] ?? [],       // Step 4: Formats
                platforms: answers[5] ?? [],            // Step 5: Platforms (LinkedIn, etc.)
                targetAudience: answers[6] ?? []        // Step 6: Audience
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
    func loadPostsIdeas() async throws -> DiscoverIdeaResponse {
        
        print("Fetching data from Supabase...")
        
        // 1. Fetch Trending Topics (The Parent Table)
        async let trendingQuery: [TrendingTopic] = client
            .from("trending_topics")
            .select()
            .execute()
            .value

        // 2. Fetch ALL Actions (Linked via topic_id)
        async let actionsQuery: [TopicAction] = client
            .from("topic_actions")
            .select()
            .execute()
            .value

        // 3. Fetch ALL Publish Ready Posts (Linked via topic_id)
        async let postsQuery: [PublishReadyPost] = client
            .from("publish_ready_posts")
            .select()
            .execute()
            .value
        
        // 4. Fetch Post Details (Linked via id -> publish_ready_posts.id)
        async let postDetailsQuery: [PostDetail] = client
            .from("post_details")
            .select()
            .execute()
            .value

        // 5. Await all results concurrently
        let (trending, allActions, allPosts, allPostDetails) = try await (
            trendingQuery,
            actionsQuery,
            postsQuery,
            postDetailsQuery
        )
        
        // MARK: - Process & Group Data

        let groupedActions = Dictionary(grouping: allActions, by: { $0.topicDetailId })
        

        let groupedPosts = Dictionary(grouping: allPosts, by: { $0.id ?? "independent" })
        

        let populatedTopics = trending.map { topic -> TrendingTopic in
            var newTopic = topic
            // Inject the children found in the dictionaries
            newTopic.actions = groupedActions[topic.id] ?? []
            newTopic.relevantPosts = groupedPosts[topic.id] ?? []
            return newTopic
        }
        
        print("Data fetched and grouped successfully!")
        
        // D. Return the response
        return DiscoverIdeaResponse(
            trendingTopics: populatedTopics,
            publishReadyPosts: allPosts,
            selectedPostDetails: allPostDetails
        )
    }
}
