//
//  Browsers.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 14/03/2024.
//

import Foundation

public enum Browsers: String, CaseIterable, Identifiable, Codable {
    public var id: Self { self }
    
    case chrome
    case safari
    
    var bundleIdentifier: String {
        switch self {
        case .chrome:
            return "com.google.chrome"
        case .safari:
            return "com.apple.safari"
        }
    }
    
    var icon: String {
        switch self {
        case .chrome:
            return "chrome-logo"
        case .safari:
            return "safari-logo"
        }
    }
}
