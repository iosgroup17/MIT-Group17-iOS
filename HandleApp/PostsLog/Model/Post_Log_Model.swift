//
//  Post_Log_Model.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 25/11/25.
//

// ScheduledPostModel.swift


import Foundation
import UIKit
import Supabase

struct Post: Codable {
    let id: String?
    let status: String?
    let postText: String
    let fullCaption: String?
    let imageName: String
    let platformName: String
    let platformIconName: String
    let scheduledAt: Date?
    let publishedAt: Date?
    let suggestedHashtags: [String]?
    let optimalPostingTimes: [String]?
    let likes: Int?
    let comments: Int?
    let reposts: Int?
    let shares: Int?
    let views: Int?
    let engagementScore: Double?

    enum CodingKeys: String, CodingKey {
        case id, status, likes, comments, reposts, shares, views
        case postText = "post_text"
        case fullCaption = "full_caption"
        case imageName = "image_name"
        case platformName = "platform_name"
        case platformIconName = "platform_icon_name"
        case scheduledAt = "scheduled_at"
        case publishedAt = "published_at"
        case suggestedHashtags = "suggested_hashtags"
        case optimalPostingTimes = "optimal_posting_times"
        case engagementScore = "engagement_score"
    }
}

extension Post {
    
    static func loadTomorrowScheduledPosts(from allPosts: [Post]) -> [Post] {
        let today = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return [] }
        return allPosts.filter { post in
            let status = post.status?.uppercased() ?? ""
            guard status == "SCHEDULED" else { return false }
            guard let scheduleDate = post.scheduledAt else { return false }
            return Calendar.current.isDate(scheduleDate, inSameDayAs: tomorrow)
        }
    }

    static func loadScheduledPostsLater(from allPosts: [Post]) -> [Post] {
        let today = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today),
              let endOfTomorrow = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: tomorrow) else {
            return []
        }
        
        return allPosts.filter { post in
            let status = post.status?.uppercased() ?? ""
            guard status == "SCHEDULED" else { return false }
            guard let scheduleDate = post.scheduledAt else { return false }
            return scheduleDate > endOfTomorrow
        }
        .sorted { ($0.scheduledAt ?? Date()) < ($1.scheduledAt ?? Date()) }
    }
    
    static func loadPublishedPosts(from allPosts: [Post]) -> [Post] {
        return allPosts.filter { post in
            // Check the 'status' column or if 'publishedAt' has a value
            return post.status == "PUBLISHED" || post.publishedAt != nil
        }
        .sorted { $0.publishedAt ?? Date() > $1.publishedAt ?? Date()
        }
    }

    static func loadSavedPosts(from allPosts: [Post]) -> [Post] {
            return allPosts.filter { $0.status?.uppercased() == "SAVED" }
    }
}
