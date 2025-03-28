//
//  LicenseValidationAPIProtocol.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 28/03/2025.
//

import Foundation

protocol LicenseValidationAPIProtocol {
    func validateLicense(_ licenseKey: String) throws -> Request<ValidateKeyResponse>
}

struct LicenseValidationAPI: LicenseValidationAPIProtocol {
    @Inject private var dataProvider: DBSDataProviderRepresentable
    
    func validateLicense(_ licenseKey: String) throws -> Request<ValidateKeyResponse> {
        guard let url = dataProvider.appConfig.baseURL?.appending(path: "/validate-key") else {
            throw ClientError.unknown
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(ValidateKeyBody(key: licenseKey))
        return Request<ValidateKeyResponse>(urlRequest: urlRequest, dataProvider: dataProvider)
    }
}
