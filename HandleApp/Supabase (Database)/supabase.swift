//
//  supabase.swift
//  HandleApp
//
//  Created by SDC-USER on 08/01/26.
//

import Supabase
import Foundation

struct UserAnalytics: Codable{
    let handle_score: Int?
    let consistency_weeks: Int
    let last_updated: String?
    
    
    let insta_score: Int?
    let insta_post_count: Int?
    let insta_engagement: Int?
    let insta_avg_engagement: Int?
    
    let linkedin_score: Int?
    let linkedin_post_count: Int?
    let linkedin_engagement: Int?
    let linkedin_avg_engagement: Int?
    
    let x_score: Int?
    let x_post_count: Int?
    let x_engagement: Int?
    let x_avg_engagement: Int?
    
    let previous_handle_score: Int?
}

struct SocialConnection: Codable {
    let user_id: UUID
    let platform: String
    let handle: String?
    let access_token: String?
}


struct OnboardingResponse: Codable {
    let user_id: UUID
    let step_index: Int
    let selection_tags: [String]
}

struct DailyAnalyticsRow: Codable {
    let date: String
    let platform: String
    let engagement: Int
}

struct DailyMetric: Identifiable {
    let id = UUID()
    let date: Date
    let engagement: Int
    let platform: String
}

struct BestPost: Codable {
    let platform: String
    let post_text: String?
    let likes: Int
    let comments: Int
    let shares_reposts: Int?
    let extra_metric: Int?
    let post_url: String?
    let post_date: String?
}


class SupabaseManager {
    static let shared = SupabaseManager()
    
    private let supabaseURL = URL(string: "https://rfoqrrppblagcurghzhy.supabase.co")!
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmb3FycnBwYmxhZ2N1cmdoemh5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4MTU0MDEsImV4cCI6MjA4MzM5MTQwMX0.PiPBEpJA5XZW2u1Nbqk4mva6p8eyP_iTcclpXEk-I9k"
    

    let client: SupabaseClient
    let testUserID = UUID(uuidString: "801e5aff-c41e-45bf-904f-bd1bc6bbcd17")!
    
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
        // Priority 1: Real Authenticated User
//        if let authID = client.auth.currentSession?.user.id {
//            return authID
//        }
        // Priority 2: Fallback for Simulator/Testing
        return testUserID
    }
    
  
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
              return []
          }
      }
      
      
    func saveSocialHandle(platform: String, handle: String) async {
        guard let userId = client.auth.currentSession?.user.id else { return }
        
        struct SocialConnectionParams: Codable {
            let user_id: UUID
            let platform: String
            let handle: String
        }
        
        let params = SocialConnectionParams(user_id: userId, platform: platform, handle: handle)
        
        do {
            
            try await client.from("social_connections")
                .upsert(params, onConflict: "user_id, platform")
                .execute()
            print("Saved \(platform) handle: \(handle)")
        } catch {
            print("Failed to save handle: \(error)")
        }
    }
      
     
    func runHandleScoreCalculation(handle: String) async -> Int {
            let params: [String: String] = ["handle": handle, "user_id": currentUserID.uuidString]
            do {
                // Invokes the edge function we just updated
                let response: [String: Int] = try await client.functions
                    .invoke("process-tweet-scrape", options: FunctionInvokeOptions(body: params))
                return response["handle_score"] ?? 0
            } catch {
                print("Scrape Error: \(error)")
                return 0
            }
        }
    
    func runInstaScoreCalculation(handle: String) async -> Int {
        let params: [String: String] = ["handle": handle, "user_id": currentUserID.uuidString]
        do {
            let response: [String: Int] = try await client.functions
                .invoke("process-insta-scrape", options: FunctionInvokeOptions(body: params))
            return response["handle_score"] ?? 0
        } catch {
            print("Instagram Scrape Error: \(error)")
            return 0
        }
    }
    
 
        func runLinkedInScoreCalculation(handle: String) async -> Int {
            guard let userId = client.auth.currentSession?.user.id else { return 0 }
            
            struct ScrapeParams: Codable {
                let handle: String
                let user_id: UUID
            }
            
       
            struct Response: Codable {
                let handle_score: Int
                let post_count: Int
            }
            
            let params = ScrapeParams(handle: handle, user_id: userId)
            
            do {
                
                let response: Response = try await client.functions
                    .invoke(
                        "process-linkedin-scrape",
                        options: FunctionInvokeOptions(body: params)
                    )
                
                print("LinkedIn Scrape: Score \(response.handle_score), Posts \(response.post_count)")
                return response.handle_score
            } catch {
                print("LinkedIn Scrape Failed: \(error)")
                return 0
            }
        }
    
    func runTwitterScoreCalculation(handle: String) async -> Int {
        guard let userId = client.auth.currentSession?.user.id else { return 0 }
        
        struct ScrapeParams: Codable {
            let handle: String
            let user_id: UUID
        }
        
        struct Response: Codable {
            let handle_score: Int
            let post_count: Int
        }
        
        let params = ScrapeParams(handle: handle, user_id: userId)
        
        do {
       
            let response: Response = try await client.functions
                .invoke(
                    "process-tweet-scrape",
                    options: FunctionInvokeOptions(body: params)
                )
            
            print("Twitter Scrape: Score \(response.handle_score), Posts \(response.post_count)")
            return response.handle_score
        } catch {
            print("Twitter Scrape Failed: \(error)")
            return 0
        }
    }
      
      
    func disconnectSocial(platform: String) async -> Bool {
        do {
           
            try await client.from("social_connections")
                .delete()
                .match(["user_id": currentUserID, "platform": platform])
                .execute()
                
            return true
        } catch {
            print("Disconnect Error: \(error)")
            return false
        }
    }
    
    func fetchDailyAnalytics() async -> [DailyMetric] {
        guard let userId = client.auth.currentSession?.user.id else { return [] }
        
        do {
            let rows: [DailyAnalyticsRow] = try await client
                .from("daily_analytics")
                .select()
                .eq("user_id", value: userId)
                .order("date", ascending: true)
                .execute()
                .value
            
            let dbFormatter = DateFormatter()
            dbFormatter.dateFormat = "yyyy-MM-dd"
            
            return rows.compactMap { row in
                guard let date = dbFormatter.date(from: row.date) else { return nil }
                return DailyMetric(
                    date: date,
                    engagement: row.engagement,
                    platform: row.platform
                )
            }
        } catch {
            print("Error fetching graph data: \(error)")
            return []
        }
    }
    
    
      
  
        func ensureAnonymousSession() async {
            if client.auth.currentSession != nil {
                print("User already has a session: \(client.auth.currentSession?.user.id.uuidString ?? "Unknown")")
                return
            }
            
            do {
                _ = try await client.auth.signInAnonymously()
                print("Created new Anonymous User: \(client.auth.currentSession?.user.id.uuidString ?? "Unknown")")
            } catch {
                print("Anonymous Auth Failed: \(error)")
            }
        }
    
    func autoUpdateAnalytics() async {
        guard let userId = client.auth.currentSession?.user.id else { return }
        
        do {
         
            let analytics: UserAnalytics = try await client
                .from("user_analytics")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            
    
            if let lastDateStr = analytics.last_updated,
               let lastDate = ISO8601DateFormatter().date(from: lastDateStr) {
                let hoursSince = Date().timeIntervalSince(lastDate) / 3600
                if hoursSince < 24 {
                    print("⏳ Data is fresh (\(Int(hoursSince))h old). Skipping auto-scrape.")
                    return
                }
            }
            
            print("Data is stale. Starting auto-scrape...")
            
       
            let connections: [SocialConnection] = try await client
                .from("social_connections")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
           
            for conn in connections {
                if let handle = conn.handle {
                    if conn.platform == "twitter" { _ = await runTwitterScoreCalculation(handle: handle) }
                    if conn.platform == "instagram" { _ = await runInstaScoreCalculation(handle: handle) }
                    if conn.platform == "linkedin" { _ = await runLinkedInScoreCalculation(handle: handle) }
                }
            }
            print("Auto-scrape completed.")
            
        } catch {
            print("Auto-update failed or no analytics row yet.")
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
            
         
            var answers: [Int: [String]] = [:]
            for resp in responses {
                answers[resp.step_index] = resp.selection_tags
            }
            
            
            return UserProfile(
                professionalIdentity: answers[0] ?? [], // Step 0: Identity
                currentFocus: answers[1] ?? [],         // Step 1: Working on
                industry: answers[2] ?? [],             // Step 2: Domain/Industry
                primaryGoals: answers[3] ?? [],         // Step 3: Goals
                contentFormats: answers[4] ?? [],       // Step 4: Formats
                platforms: answers[5] ?? [],            // Step 5: Platforms (LinkedIn, etc.)
                targetAudience: answers[6] ?? [],
            )
            
        } catch {
            print("Error assembling UserProfile: \(error)")
            return nil
        }
    }
    
  

    func fetchUserPosts() async -> [Post] {
            do {
                // Use the smart 'currentUserID'
                let targetID = self.currentUserID
                print("DEBUG: Fetching posts for User: \(targetID)")

                let posts: [Post] = try await client
                    .from("posts")
                    .select()
                    .eq("user_id", value: targetID)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                return posts
            } catch {
                print("Error fetching user posts: \(error)")
                return []
            }
        }
    
//    func createPost(post: Post) async throws {
//            // Use the smart 'currentUserID'
//            let targetID = self.currentUserID
//            
//            let postPayload = Post(
//                id: post.id ?? UUID(),
//                userId: targetID, // Attach to whichever user is active (Real or Test)
//                topicId: post.topicId,
//                status: post.status,
//                postHeading: post.postHeading,
//                fullCaption: post.fullCaption,
//                imageNames: post.imageNames,
//                platformName: post.platformName,
//                platformIconName: post.platformIconName,
//                hashtags: post.hashtags,
//                scheduledAt: post.scheduledAt,
//                publishedAt: post.publishedAt,
//                suggestedHashtags: post.suggestedHashtags
//            )
//
//            print("DEBUG: Insert Post for User: \(targetID)")
//
//            try await client
//                .from("posts")
//                .insert(postPayload)
//                .execute()
//            
//            print("DEBUG: Post inserted successfully!")
//        }


        func updatePostStatus(postId: UUID, status: Post.PostStatus, date: Date? = nil) async throws {
            var updateData: [String: AnyJSON] = ["status": .string(status.rawValue)]
            
            if let date = date {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                updateData["scheduled_at"] = .string(formatter.string(from: date))
            }

            try await client
                .from("posts")
                .update(updateData)
                .eq("id", value: postId.uuidString)
                .execute()
        }

    func deleteLogPost(id: UUID) async {
        do {
            try await client
                .from("posts")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
            print("Post deleted successfully")
        } catch {
            print("Delete error: \(error)")
        }
    }
    
    func upsertPost(post: Post) async throws {
        try await client
            .from("posts")
            .upsert(post)
            .execute()
    }
    
//    func updateScheduledPost(post: Post) async throws {
//        guard let id = post.id else { return }
//        
//        try await client
//            .from("posts") // Make sure this matches your DB table name
//            .update(post)  // Update the row with the new object
//            .eq("id", value: id) // Find the row with this ID
//            .execute()
//    }
    

    func loadPostsIdeas() async throws -> DiscoverIdeaResponse {
        
        print("Fetching discovery data from Supabase...")
        

        async let trendingQuery: [TrendingTopic] = client
            .from("trending_topics")
            .select()
            .execute()
            .value


        async let actionsQuery: [TopicAction] = client
            .from("topic_actions")
            .select()
            .execute()
            .value
        
        
        let (trending, allActions) = try await (
            trendingQuery,
            actionsQuery
        )
        
        let groupedActions = Dictionary(grouping: allActions, by: { $0.topicDetailId })
        

        let populatedTopics = trending.map { topic -> TrendingTopic in
            var newTopic = topic
            
            newTopic.actions = groupedActions[topic.id] ?? []
            
            newTopic.relevantPosts = []
            
            return newTopic
        }
        
        print("Data fetched and grouped successfully!")
        
        return DiscoverIdeaResponse(
            trendingTopics: populatedTopics
        )
    }
}
