import Foundation
import UIKit
import Supabase

// MARK: - Main Data Container
struct DiscoverIdeaResponse {
    var trendingTopics: [TrendingTopic] = []
    var publishReadyPosts: [PublishReadyPost] = []
    var topicDetails: [TopicDetail] = []
    var selectedPostDetails: [PostDetail] = []
}

struct TrendingTopic: Codable {
    let id: String
    let topicName: String
    let shortDescription: String
    let platformIcon: String
    let hashtags: [String]

    enum CodingKeys: String, CodingKey {
        case id, hashtags
        case topicName = "topic_name"
        case shortDescription = "short_description"
        case platformIcon = "platform_icon"
    }
}

struct PublishReadyPost: Codable {
    let id: String
    let topicDetailId: String?
    let postHeading: String
    let platformIcon: String
    let caption: String
    let postImage: [String]?
    let hashtags: [String]
    let predictionText: String
    
    enum CodingKeys: String, CodingKey {
        case id, caption, hashtags
        case topicDetailId = "topic_detail_id"
        case postHeading = "post_heading"
        case platformIcon = "platform_icon"
        case postImage = "post_image"
        case predictionText = "prediction_text"
    }
}

struct TopicDetail: Codable {
    let id: String
    let topicId: String
    let contextDescription: String
    var actions: [TopicAction]?
    var relevantPosts: [PublishReadyPost]?

    enum CodingKeys: String, CodingKey {
        case id
        case topicId = "topic_id"
        case contextDescription = "context_description"
        case actions
        case relevantPosts
    }
}

struct TopicAction: Codable {
    let topicDetailId: String
    let callToAction: String
    let actionDescription: String
    let destinationUrl: String?
    let actionIcon: String?

    enum CodingKeys: String, CodingKey {
        case topicDetailId = "topic_detail_id"
        case callToAction = "call_to_action"
        case actionIcon = "action_icon"
        case actionDescription = "action_description"
        case destinationUrl = "destination_url"
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
        case platformIconId = "platform_icon"
        case fullCaption = "full_caption"
        case suggestedHashtags = "suggested_hashtags"
        case optimalPostingTimes = "optimal_posting_times"
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
