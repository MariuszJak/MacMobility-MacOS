//
//  String+Ext.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 28/03/2025.
//

import Foundation

public extension String {
    static let GET = "GET"
    static let POST = "POST"
    static let PUT = "PUT"
    static let DELETE = "DELETE"
    
    func applyHTTPS() -> String {
        if self.hasPrefix("https://") {
            return self
        }
        return "https://\(self)"
    }
}

extension String {
    func appNameFromPath() -> String? {
        guard let lastComponent = self.split(separator: "/").last,
              lastComponent.hasSuffix(".app") else {
            return nil
        }
        return lastComponent.replacingOccurrences(of: ".app", with: "")
    }
}
