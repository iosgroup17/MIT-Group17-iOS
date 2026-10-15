//
//  SocialAuthManager.swift
//  HandleApp
//
//  Created by SDC_USER on 12/01/26.
//

import Foundation

class SocialAuthManager {
    static let shared = SocialAuthManager()
    var currentTwitterVerifier: String?
    private init() {}
}
