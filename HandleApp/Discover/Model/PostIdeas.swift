import Foundation
import UIKit
import Supabase

// MARK: - Main Data Container
struct DiscoverIdeaResponse {
    var trendingTopics: [TrendingTopic] = []
    var publishReadyPosts: [PublishReadyPost] = []
}

//struct TrendingTopic: Codable, Identifiable {
//    var id: String = UUID().uuidString // Auto-generate ID for local AI items
//    let topicName: String
//    let shortDescription: String
//    let platformIcon: String
//    let hashtags: [String]
//    let trendingContext: String
//    let category: String
//
//    // Map JSON keys (snake_case) to Swift properties (camelCase)
//    enum CodingKeys: String, CodingKey {
//        case id // optional, if AI sends it (it won't based on prompt)
//        case topicName = "topic_name"
//        case shortDescription = "short_description"
//        case platformIcon = "platform_icon"
//        case hashtags
//        case trendingContext = "trending_context"
//        case category
//    }
//
//    // Custom init to handle the missing ID from AI
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        // Use ID if present, otherwise generate new UUID
//        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
//
//        self.topicName = try container.decode(String.self, forKey: .topicName)
//        self.shortDescription = try container.decode(String.self, forKey: .shortDescription)
//        self.platformIcon = try container.decode(String.self, forKey: .platformIcon)
//        self.hashtags = try container.decode([String].self, forKey: .hashtags)
//        self.trendingContext = try container.decode(String.self, forKey: .trendingContext)
//        self.category = try container.decode(String.self, forKey: .category)
//    }
//}

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
        case hashtags, category
        case id = "trending_topic_id"
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
    let postImage: [PostImageRef]?
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
    

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
   
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.topicDetailId = try container.decodeIfPresent(String.self, forKey: .topicDetailId)

        
        self.postHeading = try container.decodeIfPresent(String.self, forKey: .postHeading) ?? "New Idea"
        self.platformIcon = try container.decodeIfPresent(String.self, forKey: .platformIcon) ?? "icon-linkedin"
        self.caption = try container.decodeIfPresent(String.self, forKey: .caption) ?? ""
        
  
        self.postImage = try container.decodeIfPresent([PostImageRef].self, forKey: .postImage)
        self.hashtags = try container.decodeIfPresent([String].self, forKey: .hashtags) ?? []
        
   
        self.predictionText = try container.decodeIfPresent(String.self, forKey: .predictionText) ?? "AI Generated Insight"
    }
    

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
    var id: UUID?
    let postHeading: String?
    let platformName: String
    let platformIconName: String?
    let caption: String?
    let images: [PostImageRef]?
    let hashtags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case postHeading = "post_heading"
        case platformName, platformIconName, caption, images, hashtags, id
    }
}

struct PostImageRef: Codable {
    let type: String
    let path: String
}
