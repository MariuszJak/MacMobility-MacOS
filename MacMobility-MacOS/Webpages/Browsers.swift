//
//  Browsers.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 14/03/2024.
//

import Foundation

public enum Browsers: String, CaseIterable, Identifiable, Codable {
    public var id: Self { self }
    
    case chrome
    case safari
    case orion
    
    var name: String {
        switch self {
        case .chrome:
            return "Chrome"
        case .safari:
            return "Safari"
        case .orion:
            return "Orion"
        }
    }
    
    var bundleIdentifier: String {
        switch self {
        case .chrome:
            return "com.google.chrome"
        case .safari:
            return "com.apple.safari"
        case .orion:
            return "com.kagi.kagimacOS"
        }
    }
    
    var icon: String {
        switch self {
        case .chrome:
            return "chrome-logo"
        case .safari:
            return "safari-logo"
        case .orion:
            return "orion-browser-logo"
        }
    }
}
