//
//  LicenseValidationAPIProtocol.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 28/03/2025.
//

import Foundation

protocol LicenseValidationAPIProtocol {
    func validateLicense(_ licenseKey: String, email: String) throws -> Request<ValidateKeyResponse>
}

struct LicenseValidationAPI: LicenseValidationAPIProtocol {
    @Inject private var dataProvider: DBSDataProviderRepresentable
    
    func validateLicense(_ licenseKey: String, email: String) throws -> Request<ValidateKeyResponse> {
        guard let url = dataProvider.appConfig.baseURL?.appending(path: "/validate-key") else {
            throw ClientError.unknown
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(ValidateKeyBody(key: licenseKey, email: email))
        return Request<ValidateKeyResponse>(urlRequest: urlRequest, dataProvider: dataProvider)
    }
}

public struct AppUpdateResponse: Codable {
    let latest_version: String
    let download_url: String
    let release_notes: String
}

protocol AppUpdateAPIProtocol {
    func checkForUpdate() throws -> Request<AppUpdateResponse>
}

struct AppUpdateAPI: AppUpdateAPIProtocol {
    @Inject private var dataProvider: DBSDataProviderRepresentable
    
    func checkForUpdate() throws -> Request<AppUpdateResponse> {
        guard let url = dataProvider.appConfig.baseURL?.appending(path: "/macmobiliy-version") else {
            throw ClientError.unknown
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        return Request<AppUpdateResponse>(urlRequest: urlRequest, dataProvider: dataProvider)
    }
}
