//
//  LicenseKeyGenerator.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 23/03/2025.
//

import Foundation
import CryptoKit

struct LicenseKeyGenerator {
    private let secretKey: String = "03d189f5-dcd2-4a68-be44-257c5bd3685c"

    /// Generates a unique key based on an index
    func generateKey(for index: Int) -> String {
        let indexString = "\(index)"
        let hmac = HMAC<SHA256>.authenticationCode(for: indexString.data(using: .utf8)!,
                                                   using: SymmetricKey(data: secretKey.data(using: .utf8)!))
        let hmacString = hmac.compactMap { String(format: "%02x", $0) }.joined()
        return "\(index)-\(hmacString)"
    }
    
    /// Validates a given key and extracts the index
    func validateKey(_ key: String) -> Bool {
        let components = key.split(separator: "-")
        guard components.count == 2, let index = Int(components[0]) else { return false }
        
        let expectedKey = generateKey(for: index)
        return expectedKey == key
    }
}
