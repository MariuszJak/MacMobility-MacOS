//
//  ClientError.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 28/03/2025.
//

import Foundation

public enum ClientError: Error {
    case unknown
    case notFound
    case badRequest
    case unauthorized
    case forbidden
    case methodNotAllowed
    case notAcceptable
    case requestTimeout
    case conflict
    case unprocessableContent
    case locked
    case internalServerError
    case badGateway
    case raw(Error)
}
