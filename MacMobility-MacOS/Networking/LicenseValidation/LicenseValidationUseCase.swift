//
//  LicenseValidationUseCase.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 28/03/2025.
//

import Foundation

protocol LicenseValidationUseCaseProtocol {
    func validateLicense(_ licenseKey: String) async -> Result<ValidateKeyResponse, ClientError>
}

struct LicenseValidationUseCase: LicenseValidationUseCaseProtocol {
    @Inject private var client: LicenseValidationAPIProtocol
    
    func validateLicense(_ licenseKey: String) async -> Result<ValidateKeyResponse, ClientError> {
        do {
            let result = try await client
                .validateLicense(licenseKey)
                .execute()
            switch result {
            case .success(let data):
                return .success(data)
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(.raw(error))
        }
    }
}
