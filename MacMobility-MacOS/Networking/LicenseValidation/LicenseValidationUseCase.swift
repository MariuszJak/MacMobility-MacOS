//
//  LicenseValidationUseCase.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 28/03/2025.
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

protocol AppUpdateUseCaseProtocol {
    func checkForUpdate() async -> Result<AppUpdateResponse, ClientError>
}

struct AppUpdateUseCase: AppUpdateUseCaseProtocol {
    @Inject private var client: AppUpdateAPIProtocol
    
    func checkForUpdate() async -> Result<AppUpdateResponse, ClientError> {
        do {
            let result = try await client
                .checkForUpdate()
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
