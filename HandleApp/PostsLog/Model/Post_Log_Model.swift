//
//  Post_Log_Model.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 25/11/25.
//

// ScheduledPostModel.swift

import Foundation
import UIKit

struct Post: Decodable {
    
    let text: String
    let fullCaption: String?
    let time: String?
    let date: Date?
    let platformIconName: String
    let platformName: String
    let imageName: String
    let isPublished: Bool
    let likes: String?
    let comments: String?
    let reposts: String?
    let shares: String?
    let views: String?
    let engagementScore: String?
    let suggestedHashtags: [String]?
    let optimalPostingTimes: [String]?
}

extension Post {
    
    // MARK: - Shared Configuration
    
    // 💡 Helper: A centralized decoder to ensure all functions parse dates exactly the same way.
    private static var standardDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        // Matches format: "2025-11-26T09:30:00+0000"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }

    // MARK: - Data Loaders
    
    // 1. TODAY (Real Time)
    static func loadTodayScheduledPosts(from filename: String = "Posts_data") throws -> [Post] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            return []
        }
        
        let data = try Data(contentsOf: url)
        let posts = try standardDecoder.decode([Post].self, from: data)
        
        // 💡 REAL TIME LOGIC:
        let today = Date()
        
        return posts.filter { post in
            guard let postDate = post.date, let time = post.time, !time.isEmpty else { return false }
            
            // Check if postDate is strictly "Today"
            return Calendar.current.isDate(postDate, inSameDayAs: today)
        }
    }
    
    // 2. TOMORROW (Real Time)
    static func loadTomorrowScheduledPosts(from filename: String = "Posts_data") throws -> [Post] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            return []
        }
        
        let data = try Data(contentsOf: url)
        let posts = try standardDecoder.decode([Post].self, from: data)
        
        // 💡 REAL TIME LOGIC:
        let today = Date()
        // Calculate exactly 1 day from now
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return [] }
        
        return posts.filter { post in
            guard let postDate = post.date, let time = post.time, !time.isEmpty else { return false }
            
            // Check if postDate is strictly "Tomorrow"
            return Calendar.current.isDate(postDate, inSameDayAs: tomorrow)
        }
    }
    
    // 3. LATER (After Tomorrow)
    static func loadScheduledPostsAfterDate(from filename: String = "Posts_data") throws -> [Post] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            return []
        }
        
        let data = try Data(contentsOf: url)
        let posts = try standardDecoder.decode([Post].self, from: data)
        
        // 💡 REAL TIME LOGIC:
        let today = Date()
        
        // Calculate the END of tomorrow. Anything after that is "Later".
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today),
              let endOfTomorrow = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: tomorrow) else {
            return []
        }

        let filteredPosts = posts.filter { post in
            guard let postDate = post.date, let time = post.time, !time.isEmpty else { return false }
            
            // Return true if the date is AFTER tomorrow night
            return postDate > endOfTomorrow
        }
        
        // Sort by date ascending (so nearest future posts appear first)
        return filteredPosts.sorted { $0.date! < $1.date! }
    }
    
    // 4. PUBLISHED (Unchanged logic, just centralized decoder)
    static func loadPublishedPosts(from filename: String = "Posts_data") throws -> [Post] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        let posts = try standardDecoder.decode([Post].self, from: data)
        
        return posts.filter { $0.isPublished }
    }
    
    // 5. ALL POSTS (For Calendar Dots)
    static func loadAllPosts(from fileName: String) throws -> [Post] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try standardDecoder.decode([Post].self, from: data)
    }
    static func loadSavedPosts(from filename: String = "Posts_data") throws -> [Post] {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                throw NSError(domain: "Post_Log_Model", code: 404,
                              userInfo: [NSLocalizedDescriptionKey: "Couldn't find \(filename).json file."])
            }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                // Step 2: Decode the array
                let posts = try decoder.decode([Post].self, from: data)
                let filteredPosts = posts.filter { post in
                    if let time = post.time, !time.isEmpty {
                        return false
                    }
                    return true
                }
                
                // Helpful Debugging: Check if data was actually loaded
                if filteredPosts.isEmpty {
                    print("DEBUG: Successfully decoded JSON, but the array is empty.")
                }
                return filteredPosts
            } catch {
                // If decoding fails (JSON keys don't match properties), this error is thrown.
                print("Decoding Failed: \(error.localizedDescription)")
                throw error
            }
        }
}
