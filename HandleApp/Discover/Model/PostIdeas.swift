import Foundation
import UIKit
import Supabase

// MARK: - Main Data Container
struct DiscoverIdeaResponse {
    var trendingTopics: [TrendingTopic] = []
    var publishReadyPosts: [PublishReadyPost] = []
}

struct TrendingTopic: Codable {
    let id: String
    let topicName: String
    let shortDescription: String
    let platformIcon: String
    let hashtags: [String]
    let trendingContext: String
    var actions: [TopicAction]?
    var relevantPosts: [PublishReadyPost]?
    let category: String

    enum CodingKeys: String, CodingKey {
        case id, hashtags, category
        case topicName = "topic_name"
        case shortDescription = "short_description"
        case platformIcon = "platform_icon"
        case trendingContext = "trending_context"
        case actions
        case relevantPosts
    }
}


struct PublishReadyPost: Codable, Identifiable {
    var id: String = UUID().uuidString
    
    let topicDetailId: String?
    let postHeading: String
    let platformIcon: String
    let caption: String
    let postImage: [String]?
    let hashtags: [String]
    let predictionText: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case topicDetailId = "topic_detail_id"
        case postHeading = "post_heading"
        case platformIcon = "platform_icon"
        case caption
        case postImage = "post_image"
        case hashtags
        case predictionText = "prediction_text"
    }
    
    // ✅ ROBUST DECODER: Never fails on missing keys
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 1. ID: Try decode, else generate
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.topicDetailId = try container.decodeIfPresent(String.self, forKey: .topicDetailId)
        
        // 2. REQUIRED FIELDS (With Fallbacks)
        // If the AI or Database returns null/missing, we default to a safe value instead of crashing.
        self.postHeading = try container.decodeIfPresent(String.self, forKey: .postHeading) ?? "New Idea"
        self.platformIcon = try container.decodeIfPresent(String.self, forKey: .platformIcon) ?? "icon-linkedin"
        self.caption = try container.decodeIfPresent(String.self, forKey: .caption) ?? ""
        
        // 3. ARRAYS
        self.postImage = try container.decodeIfPresent([String].self, forKey: .postImage)
        self.hashtags = try container.decodeIfPresent([String].self, forKey: .hashtags) ?? []
        
        // 4. PREDICTION
        self.predictionText = try container.decodeIfPresent(String.self, forKey: .predictionText) ?? "AI Generated Insight"
    }
    
    // Helper init for manual creation
    init(postHeading: String, platformIcon: String, caption: String, hashtags: [String], predictionText: String) {
        self.id = UUID().uuidString
        self.topicDetailId = nil
        self.postHeading = postHeading
        self.platformIcon = platformIcon
        self.caption = caption
        self.postImage = nil
        self.hashtags = hashtags
        self.predictionText = predictionText
    }
}


struct TopicAction: Codable {
    let topicDetailId: String
    let callToAction: String
    let actionDescription: String
    let destinationUrl: String?
    let actionIcon: String?

    enum CodingKeys: String, CodingKey {
        case topicDetailId = "topic_id"
        case callToAction = "call_to_action"
        case actionIcon = "action_icon"
        case actionDescription = "action_description"
        case destinationUrl = "destination_url"
    }
}


struct EditorDraftData: Codable {
    let platformName: String
    let platformIconName: String?
    let caption: String?
    let images: [String]?
    let hashtags: [String]?
    let postingTimes: [String]?
}
