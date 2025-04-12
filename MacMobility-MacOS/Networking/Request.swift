//
//  Request.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 28/03/2025.
//

import Foundation

public struct Request<T: Codable> {
    internal let urlRequest: URLRequest
    internal let dataProvider: DBSDataProviderRepresentable
    
    public init(urlRequest: URLRequest, dataProvider: DBSDataProviderRepresentable) {
        self.urlRequest = urlRequest
        self.dataProvider = dataProvider
    }
    
    public func execute() async throws -> Result<T, ClientError> {
        let (data, response) = try await dataProvider.execute(urlRequest: urlRequest)
        return try await handleResponse(with: data, response: response)
    }
}

extension Request {
    func handleResponse(with data: Data, response: URLResponse) async throws -> Result<T, ClientError> {
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200...300:
                break
            case 400:
                return .failure(.badRequest)
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.unauthorized)
            case 404:
                return .failure(.notFound)
            case 405:
                return .failure(.methodNotAllowed)
            case 406:
                return .failure(.notAcceptable)
            case 408:
                return .failure(.requestTimeout)
            case 409:
                return .failure(.conflict)
            case 423:
                return .failure(.locked)
            case 500:
                return .failure(.internalServerError)
            case 502:
                return .failure(.badGateway)
            default:
                break
            }
        }
        
        do {
            let object = try JSONDecoder().decode(T.self, from: data)
            return .success(object)
        } catch {
            return .failure(.raw(error))
        }
    }
}
