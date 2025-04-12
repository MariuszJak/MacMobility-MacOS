//
//  DBSDataProviderRepresentable.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 28/03/2025.
//

import Foundation

public protocol DBSDataProviderRepresentable {
    var configuration: URLSessionConfiguration { get }
    var urlSession: URLSession { get }
    var appConfig: AppConfig! { get }
    func execute(urlRequest: URLRequest) async throws -> (Data, URLResponse)
}

public struct AppConfig: Codable {
    let serviceURL: String
    
    public var baseURL: URL? {
        URL(string: serviceURL)
    }
    
    public init(serviceURL: String) {
        self.serviceURL = serviceURL
    }
}
