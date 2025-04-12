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
        #if DEBUG
        self.appConfig = .init(serviceURL: "http://192.168.68.123:3000")
        #elseif RELEASE
        self.appConfig = .init(serviceURL: "https://www.coderblocks.eu")
        #endif
    }
    
    public func execute(urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await urlSession.data(for: urlRequest)
    }
}
