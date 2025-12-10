//
//  Post_Log_Model.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 25/11/25.
//

// ScheduledPostModel.swift

import Foundation

struct Post: Decodable {
    
    let text: String
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
}

extension Post {
    
    static func createTargetDate(day: Int, month: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        // This gives us the start of the day (e.g., 2025-11-26 00:00:00)
        return Calendar.current.date(from: components)
    }
    
    // 💡 Define a custom ISO 8601 decoder to ensure decoding works
    static let isoDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // Use a compatible date strategy for your JSON data
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    static func loadTodayScheduledPosts(from filename: String = "Posts_data") throws -> [Post] {
        // Step 1: Check Bundle URL
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            // If the file is not found (Target Membership issue), this error is thrown.
            throw NSError(domain: "Post_Log_Model", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "ERROR: \(filename).json not found in main bundle."])
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let targetDate = Post.createTargetDate(day: 26, month: 11, year: 2025) else {
            throw NSError(domain: "Post_Log_Model", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not create target date."])
        }
        do {
            // Step 2: Decode the array
            let posts = try decoder.decode([Post].self, from: data)
            let filteredPosts = posts.filter { post in
                
                // 1. Check if the post is scheduled (time property exists)
                let isScheduled = post.time != nil && !post.time!.isEmpty
                
                // 2. Check if the post has a date AND that date matches the target day
                let isTargetDate = (post.date != nil) &&
                Calendar.current.isDate(post.date!, inSameDayAs: targetDate)
                
                // Return true only if BOTH conditions are met
                return isScheduled && isTargetDate }
            
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
    static func loadTomorrowScheduledPosts(from filename: String = "Posts_data") throws -> [Post] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw NSError(domain: "Post_Log_Model", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Couldn't find \(filename).json file."])
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let targetDate = Post.createTargetDate(day: 27, month: 11, year: 2025) else {
            throw NSError(domain: "Post_Log_Model", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not create target date."])
        }
        do {
            // Step 2: Decode the array
            let posts = try decoder.decode([Post].self, from: data)
            let filteredPosts = posts.filter { post in
                
                // 1. Check if the post is scheduled (time property exists)
                let isScheduled = post.time != nil && !post.time!.isEmpty
                
                // 2. Check if the post has a date AND that date matches the target day
                let isTargetDate = (post.date != nil) &&
                Calendar.current.isDate(post.date!, inSameDayAs: targetDate)
                
                // Return true only if BOTH conditions are met
                return isScheduled && isTargetDate }
            
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
    static func loadScheduledPostsAfterDate(from filename: String = "Posts_data") throws -> [Post] {
        
        // --- Setup: Find File and Decoder ---
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw NSError(domain: "Post_Log_Model", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Couldn't find \(filename).json file."])
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // --- 💡 TARGET DATE CHANGE: Create the specific boundary date (1st Dec 2025) ---
        // Note: The comparison logic will look for posts strictly AFTER this date.
        guard let targetDate = Post.createTargetDate(day: 1, month: 12, year: 2025) else {
            throw NSError(domain: "Post_Log_Model", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not create target date."])
        }
        
        do {
            // Step 1: Decode the array
            let posts = try decoder.decode([Post].self, from: data)
            
            // --- 💡 FILTERING LOGIC CHANGE: Check for 'isAfter' ---
            let filteredPosts = posts.filter { post in
                
                // 1. Check if the post is scheduled (time property exists)
                let isScheduled = post.time != nil && post.time!.isEmpty == false
                
                // 2. Check if the post has a date AND that date is STRICTLY AFTER the target date
                let isAfterTargetDate = (post.date != nil) &&
                post.date! >= targetDate // The core change: using the '>' operator
                
                // Return true only if BOTH conditions are met
                return isScheduled && isAfterTargetDate
            }
            
            // Helpful Debugging: Check if data was actually loaded
            if filteredPosts.isEmpty {
                print("DEBUG: Successfully decoded JSON, but no scheduled posts found after 1/12/2025.")
            }
            
            // --- 💡 Sorting ---
            // It's often helpful to sort future posts by date
            let sortedPosts = filteredPosts.sorted { $0.date! < $1.date! }
            
            return sortedPosts
            
        } catch {
            // If decoding fails (JSON keys don't match properties), this error is thrown.
            print("Decoding Failed: \(error.localizedDescription)")
            throw error
        }
    }
    static func loadPublishedPosts(from filename: String = "Posts_data") throws -> [Post] {
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
            let filteredPosts = posts.filter { $0.isPublished }
            
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
