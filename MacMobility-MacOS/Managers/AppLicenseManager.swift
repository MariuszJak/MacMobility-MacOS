//
//  AppLicenseManager.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 23/03/2025.
//

import Foundation

public enum LicenseType: String, Codable {
    case free
    case paid
}

public class AppLicenseManager: ObservableObject {
    public static let shared: AppLicenseManager = .init()
    var license: LicenseType = .free
    public var completion: ((LicenseType) -> Void)?
    
    public init() {
        self.license = UserDefaults.standard.get(key: .license) ?? .free
        completion?(license)
    }
    
    public func checkLicenseStatus() -> LicenseType {
        completion?(license)
        return license
    }
    
    public func degrade() {
        license = .free
        completion?(license)
        UserDefaults.standard.store(license, for: .license)
    }
    
    public func validate(key: String) -> Bool {
        if LicenseKeyGenerator().validateKey(key) {
            upgrade()
            return true
        } else {
            return false
        }
    }
    
    private func upgrade() {
        license = .paid
        completion?(license)
        UserDefaults.standard.store(license, for: .license)
    }
}
