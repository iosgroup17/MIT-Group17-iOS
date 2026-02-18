//
//  NotificationsManager.swift
//  HandleApp
//
//  Created by SDC_USER on 18/02/26.
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // 1. Request Permission
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // 2. Schedule Notification for SCHEDULED posts (3 Hours Before)
    func schedulePostReminder(for post: Post) {
        guard let postId = post.id, let scheduledDate = post.scheduledAt else { return }
        
        // Calculate 3 hours (10,800 seconds) before the scheduled time
        let triggerDate = scheduledDate.addingTimeInterval(-10800)
        
        if triggerDate < Date() { return } // Don't schedule if time has passed
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Post: \(post.platformName)"
        content.body = "Your post is scheduled for \(formatTime(scheduledDate)). Check it now!"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: postId.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        print("Scheduled reminder for \(triggerDate)")
    }
    
    // 3. Schedule Notification for SAVED/DRAFT posts (2 Days After)
    func scheduleDraftReminder(for post: Post) {
        guard let postId = post.id else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Unfinished Draft: \(post.platformName)"
        content.body = "You saved a draft 2 days ago. Don't forget to schedule it!"
        content.sound = .default
        
        // 2 Days in seconds = 172,800 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 172800, repeats: false)
        
        let request = UNNotificationRequest(identifier: postId.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        print("Draft reminder set for 2 days from now")
    }
    
    // 4. Cancel Notification (Call this when deleting or moving posts)
    func cancelNotification(for postId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [postId.uuidString])
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
