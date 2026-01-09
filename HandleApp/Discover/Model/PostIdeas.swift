import Foundation
import UIKit
import Supabase

// MARK: - Main Data Container
// This struct now just holds the data once fetched. It no longer loads itself.
struct PostIdeasResponse {
    var topIdeas: [TopIdea] = []
    var trendingTopics: [TrendingTopic] = []
    var topicIdeas: [TopicIdeaGroup] = [] // We will build this manually from the flat DB list
    var recommendations: [Recommendation] = []
    var selectedPostDetails: [PostDetail] = []
}

// MARK: - Supabase Loader
// This class handles fetching data from the 5 different database tables
class PostIdeasLoader {
    static let shared = PostIdeasLoader()
    
    func loadFromSupabase() async throws -> PostIdeasResponse {
        let client = SupabaseManager.shared.client
        
        print("🌍 Fetching data from Supabase...")
        
        // 1. Fetch all tables in parallel for speed
        async let topIdeasQuery: [TopIdea] = client.from("top_ideas").select().execute().value
        async let topicsQuery: [TrendingTopic] = client.from("trending_topics").select().execute().value
        async let recommendationsQuery: [Recommendation] = client.from("recommendations").select().execute().value
        async let postDetailsQuery: [PostDetail] = client.from("post_details").select().execute().value
        
        // Fetch flat list of topic ideas (we will group them later)
        async let flatTopicIdeasQuery: [TopicIdea] = client.from("topic_ideas").select().execute().value
        
        // 2. Wait for all data to arrive
        let (topIdeas, trendingTopics, recommendations, postDetails, flatTopicIdeas) = try await (
            topIdeasQuery,
            topicsQuery,
            recommendationsQuery,
            postDetailsQuery,
            flatTopicIdeasQuery
        )
        
        // 3. Process the data (Group flat topic ideas into sections)
        // Group by topic_id
        let groupedIdeas = Dictionary(grouping: flatTopicIdeas, by: { $0.topicId })
        
        // Map to your TopicIdeaGroup struct
        let topicIdeaGroups = groupedIdeas.map { (key, value) in
            TopicIdeaGroup(topicId: key, ideas: value)
        }
        
        print("✅ Data fetched successfully!")
        
        // 4. Return the combined object
        return PostIdeasResponse(
            topIdeas: topIdeas,
            trendingTopics: trendingTopics,
            topicIdeas: topicIdeaGroups,
            recommendations: recommendations,
            selectedPostDetails: postDetails
        )
    }
}

// MARK: - Updated Models (Matching DB Columns)

struct TopIdea: Codable, Identifiable {
    let id: String
    let caption: String
    let image: String? // Optional in DB
    let whyThisPost: [String]
    let platformName: String

    enum CodingKeys: String, CodingKey {
        case id, caption, image
        case whyThisPost = "why_this_post"
        case platformName = "platform_name"
    }
}

struct TrendingTopic: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    
    // UI Helper: Computed property (not from DB)
    var color: UIColor {
        switch id {
        case "topic_1": return UIColor.systemBlue
        case "topic_2": return UIColor.systemGreen
        case "topic_3": return UIColor.systemOrange
        case "topic_4": return UIColor.systemPurple
        case "topic_5": return UIColor.systemPink
        default:        return UIColor.systemGray
        }
    }
}

// Helper struct for UI (Does not exist in DB)
struct TopicIdeaGroup {
    let topicId: String
    let ideas: [TopicIdea]
}

struct TopicIdea: Codable, Identifiable {
    let id: String
    let topicId: String // Added this to link to parent topic
    let caption: String
    let whyThisPost: String
    let image: String?
    let platformIcon: String

    enum CodingKeys: String, CodingKey {
        case id, caption, image
        case topicId = "topic_id" // Matches DB column
        case whyThisPost = "why_this_post"
        case platformIcon = "platform_icon"
    }
}

struct Recommendation: Codable, Identifiable {
    let id: String
    let caption: String
    let whyThisPost: String
    let image: String?
    let platform: String

    enum CodingKeys: String, CodingKey {
        case id, caption, image
        case whyThisPost = "why_this_post"
        case platform = "platform_icon" // Maps 'platform_icon' in DB to 'platform' in Swift
    }
}

struct PostDetail: Codable {
    let id: String
    let platformName: String?
    let platformIconId: String?
    let fullCaption: String?
    let images: [String]?
    let suggestedHashtags: [String]?
    let optimalPostingTimes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case images
        case platformName = "platform_name"
        case platformIconId = "platform_icon" // Matches DB column
        case fullCaption = "full_caption"
        case suggestedHashtags = "suggested_hashtags"
        case optimalPostingTimes = "optimal_posting_times"
    }
}

// MARK: - Local UI Models (Not in DB)
struct EditorDraftData: Codable {
    let platformName: String
    let platformIconName: String?
    let caption: String?
    let images: [String]?
    let hashtags: [String]?
    let postingTimes: [String]?
}

