//
//  AppLicenseManager.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 23/03/2025.
//

import Foundation
import AppKit

public enum LicenseType: String, Codable {
    case free
    case paid
}

public struct ValidateKeyResponse: Codable {
    let success: Bool
    let message: String
}

public struct ValidateKeyBody: Codable {
    let key: String
}

public class AppLicenseManager: ObservableObject {
    @Inject private var useCase: LicenseValidationUseCaseProtocol
    public static let shared: AppLicenseManager = .init()
    var license: LicenseType = .free
    public var completion: ((LicenseType) -> Void)?
    
    public init() {
//        UserDefaults.standard.clear(key: .license)
        self.license = UserDefaults.standard.getUserDefaults(key: .license) ?? .free
        completion?(license)
    }
    
    public func checkLicenseStatus() -> LicenseType {
        completion?(license)
        return license
    }
    
    public func degrade() {
        license = .free
        completion?(license)
        UserDefaults.standard.storeUserDefaults(license, for: .license)
    }
    
    @MainActor
    public func validate(key: String, completion: @escaping (Bool) -> Void) async {
        if LicenseKeyGenerator().validateKey(key) {
            let result = await useCase.validateLicense(key)
            switch result {
            case .success(let body):
                if body.success {
                    upgrade()
                    UserDefaults.standard.storeUserDefaults(key, for: .licenseKey)
                    completion(true)
                } else {
                    completion(false)
                }
            case .failure:
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    private func upgrade() {
        license = .paid
        completion?(license)
        UserDefaults.standard.storeUserDefaults(license, for: .license)
    }
}
