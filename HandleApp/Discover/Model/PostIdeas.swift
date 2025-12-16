//
//  PostIdeas.swift
//  OnboardingScreens
//
//  Created by SDC-USER on 26/11/25.
//

import Foundation
import UIKit

struct PostIdeasResponse: Codable {

    var topIdeas: [TopIdea] = []
    var trendingTopics: [TrendingTopic] = []
    var topicIdeas: [TopicIdeaGroup] = []
    var recommendations: [Recommendation] = []
    var selectedPostDetails: [PostDetail] = []

    init() {
        do {
            let response = try load()
            topIdeas = response.topIdeas
            trendingTopics = response.trendingTopics
            topicIdeas = response.topicIdeas
            recommendations = response.recommendations
            selectedPostDetails = response.selectedPostDetails
        } catch {
            print("JSON Load Error:", error.localizedDescription)
        }
    }

enum CodingKeys: String, CodingKey {
        case topIdeas = "top_ideas"
        case trendingTopics = "trending_topics"
        case topicIdeas = "topic_ideas"
        case recommendations
        case selectedPostDetails = "selected_post_details"
    }
}

struct TopIdea: Codable, Identifiable {
    let id: String
    let caption: String
    let image: String
    let platformIcon: String

    enum CodingKeys: String, CodingKey {
        case id
        case caption
        case image
        case platformIcon = "platform_icon"
    }

}

struct TrendingTopic: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String

    enum CodingKeys: String, CodingKey {
        case id, name, icon
    }

    // Each topic gets a unique color
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

struct TopicIdeaGroup: Codable {
    let topicId: String
    let ideas: [TopicIdea]

    enum CodingKeys: String, CodingKey {
        case topicId = "topic_id"
        case ideas
    }
}

struct TopicIdea: Codable, Identifiable {
    let id: String
    let caption: String
    let whyThisPost: String
    let image: String
    let platformIcon: String

    enum CodingKeys: String, CodingKey {
        case id, caption, image
        case whyThisPost = "why_this_post"
        case platformIcon = "platform_icon"
    }
}

struct Recommendation: Codable, Identifiable {
    let id: String
    let caption: String
    let whyThisPost: String
    let image: String
    let platform: String

    enum CodingKeys: String, CodingKey {
        case id
        case caption
        case whyThisPost = "why_this_post"
        case image
        case platform = "platform_icon"
    }

}

struct PostDetail: Codable {
    let id: String
    let platformName: String?       // New field from your JSON
    let platformIconId: String?
    let fullCaption: String?
    let images: [String]?
    let suggestedHashtags: [String]?
    let optimalPostingTimes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case platformName = "platform_name"
        case platformIconId = "platform_icon_id"
        case fullCaption = "full_caption"
        case images
        case suggestedHashtags = "suggested_hashtags"
        case optimalPostingTimes = "optimal_posting_times"
    }
}

struct EditorDraftData {
    let platformName: String
    let platformIconName: String
    let caption: String
    
    let images: [String]
    let hashtags: [String]
    let postingTimes: [String]      
}

// JSON Loading Helper
extension PostIdeasResponse {

    func load(from filename: String = "post_ideas") throws -> PostIdeasResponse {

        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw NSError(domain: "PostIdeasResponse",
                          code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "\(filename).json not found"])
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        print(String(data: data, encoding: .utf8) ?? "")

        do {
            return try decoder.decode(PostIdeasResponse.self, from: data)
        } catch {
            print("Decoding Error:", error.localizedDescription)
            throw error
        }
    }

    func decode(from data: Data) throws -> PostIdeasResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(PostIdeasResponse.self, from: data)
    }
}
