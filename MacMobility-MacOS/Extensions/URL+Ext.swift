//
//  URL+Ext.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 28/03/2025.
//

import Foundation

public extension URL {
    func addQueryParams(params: [String: String]) -> URL? {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        let queryItems = params.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        urlComponents.queryItems = queryItems
        
        return urlComponents.url
    }
}
