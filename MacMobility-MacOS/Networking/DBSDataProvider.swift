//
//  DBSDataProvider.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 28/03/2025.
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
        self.appConfig = .init(serviceURL: "http://192.168.68.113:3000")
    }
    
    public func execute(urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await urlSession.data(for: urlRequest)
    }
}
