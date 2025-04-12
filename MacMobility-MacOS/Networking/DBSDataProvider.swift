//
//  DBSDataProvider.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 28/03/2025.
//

import Foundation

public class DBSDataProvider: DBSDataProviderRepresentable {
    public let configuration: URLSessionConfiguration
    public var appConfig: AppConfig!
    
    public var urlSession: URLSession {
        URLSession(configuration: configuration)
    }
    
    public init(configuration: URLSessionConfiguration = .default) {
        self.configuration = configuration
        self.appConfig = .init(serviceURL: "https://www.coderblocks.eu")
    }
    
    public func execute(urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await urlSession.data(for: urlRequest)
    }
}
