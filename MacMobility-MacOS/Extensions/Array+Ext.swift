//
//  Array+Ext.swift
//  MacMobility
//
//  Created by CoderBlocks on 22/07/2023.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Collection where Element == String {
    func extractWebsiteNames() -> [String] {
        return self.compactMap { urlString in
            var formattedUrlString = urlString
            if !formattedUrlString.starts(with: "http") {
                formattedUrlString = "https://" + formattedUrlString
            }
            
            guard let url = URL(string: formattedUrlString),
                  let host = url.host else {
                return nil
            }
            
            var name = host.replacingOccurrences(of: "www.", with: "")
            if let firstComponent = name.split(separator: ".").first {
                name = String(firstComponent)
            }
            
            return name.prefix(1).uppercased() + name.dropFirst()
        }
    }
}
