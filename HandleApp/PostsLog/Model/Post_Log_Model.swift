import Foundation
import UIKit
import Supabase

struct Post: Codable, Identifiable {
    let id: UUID?
    let userId: UUID        // Links to profiles.id
    let topicId: UUID?      // Link to the trend (optional)
    
    // STRICT ENUM (Matches DB)
    var status: PostStatus
    
    // Content
    var postHeading: String
    var fullCaption: String?
    var imageNames: [String]? 
    var platformName: String
    var platformIconName: String?
    let hashtags: [String]?
    var optimalPostingTimes: [String]?
    
    // Scheduling
    var scheduledAt: Date?
    var publishedAt: Date?
    
    // Analytics & Meta
    var likes: Int?
    var engagementScore: Double?

    enum PostStatus: String, Codable {
        case saved = "SAVED"
        case scheduled = "SCHEDULED"
        case published = "PUBLISHED"
    }

    enum CodingKeys: String, CodingKey {
        case id, status, likes, hashtags
        case userId = "user_id"
        case topicId = "topic_id"
        case postHeading = "post_heading"
        case fullCaption = "full_caption"
        case imageNames = "image_names"
        case platformName = "platform_name"
        case platformIconName = "platform_icon_name"
        case scheduledAt = "scheduled_at"
        case publishedAt = "published_at"
        case engagementScore = "engagement_score"
        case optimalPostingTimes = "optimal_posting_times"
    }
}

// MARK: - Helper Filters
extension Post {
    
    static func loadTomorrowScheduledPosts(from allPosts: [Post]) -> [Post] {
        let today = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return [] }
        
        return allPosts.filter { post in
            guard post.status == .scheduled, let date = post.scheduledAt else { return false }
            return Calendar.current.isDate(date, inSameDayAs: tomorrow)
        }
    }

    static func loadScheduledPostsLater(from allPosts: [Post]) -> [Post] {
        let today = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today),
              let endOfTomorrow = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: tomorrow) else { return [] }
        
        return allPosts.filter { post in
            guard post.status == .scheduled, let date = post.scheduledAt else { return false }
            return date > endOfTomorrow
        }
        .sorted { ($0.scheduledAt ?? Date()) < ($1.scheduledAt ?? Date()) }
    }
    
    static func loadPublishedPosts(from allPosts: [Post]) -> [Post] {
        return allPosts.filter { $0.status == .published }
            .sorted { ($0.publishedAt ?? Date()) > ($1.publishedAt ?? Date()) }
    }

    static func loadSavedPosts(from allPosts: [Post]) -> [Post] {
        return allPosts.filter { $0.status == .saved }
            .sorted { ($0.scheduledAt ?? Date()) > ($1.scheduledAt ?? Date()) } // Newest first
    }
}
