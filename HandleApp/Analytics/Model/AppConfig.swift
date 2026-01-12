//
//  AppConfig.swift
//  HandleApp
//
//  Created by SDC-USER on 12/01/26.
//

import Foundation

struct AppConfig {
   
    static var twitterClientID: String {
        return Bundle.main.object(forInfoDictionaryKey: "TwitterClientID") as? String ?? ""
    }
   
    static var instagramAppID: String {
        return Bundle.main.object(forInfoDictionaryKey: "InstagramAppID") as? String ?? ""
    }
   
    static var instagramAppSecret: String {
        return Bundle.main.object(forInfoDictionaryKey: "InstagramAppSecret") as? String ?? ""
    }
   
    static var linkedInClientID: String {
        return Bundle.main.object(forInfoDictionaryKey: "LinkedInClientID") as? String ?? ""
    }
   
    static var linkedInClientSecret: String {
        return Bundle.main.object(forInfoDictionaryKey: "LinkedInClientSecret") as? String ?? ""
    }
}
