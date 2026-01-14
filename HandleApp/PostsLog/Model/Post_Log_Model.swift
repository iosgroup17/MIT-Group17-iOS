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

extension SupabaseManager {
    
    // Fetch all posts for the current user
    func fetchPosts() async -> [Post] {
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
    func deletePost(id: String) async {
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
}
extension Post {
    //Date and Time Decoder
    private static var standardDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
    
    static func loadTomorrowScheduledPosts(from allPosts: [Post]) -> [Post] {
        let today = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return [] }
        return allPosts.filter { post in
            // 1. CHECK STATUS FIRST
            let status = post.status?.uppercased() ?? ""
            guard status == "SCHEDULED" else { return false }
            
            // 2. CHECK DATE
            guard let scheduleDate = post.scheduledAt else { return false }
            return Calendar.current.isDate(scheduleDate, inSameDayAs: tomorrow)
        }
    }

    static func loadScheduledPostsAfterDate(from allPosts: [Post]) -> [Post] {
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
        }
    
    static func loadAllPosts(from fileName: String) throws -> [Post] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try standardDecoder.decode([Post].self, from: data)
    }

    static func loadSavedPosts(from allPosts: [Post]) -> [Post] {
            return allPosts.filter { $0.status?.uppercased() == "SAVED" }
    }
}
