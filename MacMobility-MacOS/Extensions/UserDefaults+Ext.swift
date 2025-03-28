//
//  UserDefaults+Ext.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 14/03/2024.
//

import Foundation

public struct Pages: Codable {
    let pages: Int
}

public struct Lifecycle: Codable {
    let openCount: Int
}

extension UserDefaults {
    func store<T: Codable>(_ entity: T, for key: Const) {
        guard let jsonData = try? JSONEncoder().encode(entity) else {
            return
        }

        set(jsonData, forKey: key)
    }
    
    func get<T: Codable>(key: Const) -> T? {
        guard let itemsData = object(forKey: key) as? Data,
              let object = try? JSONDecoder().decode(T.self, from: itemsData) else {
            return nil
        }
        return object
    }
    
    func clear(key: Const) {
        set(nil, forKey: key)
    }
    
    func clearAll() {
        for key in Const.allCases {
            set(nil, forKey: key)
        }
    }
}

extension UserDefaults {
    enum Const: String, CaseIterable {
        case webItems
        case workspaceItems
        case shortcuts
        case pages
        case utilities
        case license
        case firstActivationDate
        case userApps
        case lifecycle
    }

    func set(_ value: Any?, forKey defaultName: Const) {
        set(value, forKey: defaultName.rawValue)
    }

    func object(forKey defaultName: Const) -> Any? {
        object(forKey: defaultName.rawValue)
    }
}
