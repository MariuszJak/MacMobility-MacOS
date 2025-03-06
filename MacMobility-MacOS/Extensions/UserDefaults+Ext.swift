//
//  UserDefaults+Ext.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 14/03/2024.
//

import Foundation

extension UserDefaults {
    func storeWebItems(_ webItems: [WebpageItem]) {
        guard let jsonData = try? JSONEncoder().encode(webItems) else {
            return
        }

        set(jsonData, forKey: Const.webItems)
    }

    func getWebItems() -> [WebpageItem]? {
        guard let itemsData = object(forKey: Const.webItems) as? Data,
              let items = try? JSONDecoder().decode([WebpageItem].self, from: itemsData) else {
            return nil
        }
        return items
    }
    
    func storeWorkspaceItems(_ workspaceItems: [WorkspaceItem]) {
        guard let jsonData = try? JSONEncoder().encode(workspaceItems) else {
            return
        }

        set(jsonData, forKey: Const.workspaceItems)
    }
    
    func storeWorkspaceItems2(_ workspaceItems: [WorkspaceItem]) {
        guard let jsonData = try? JSONEncoder().encode(workspaceItems) else {
            return
        }

        set(jsonData, forKey: Const.workspaceItems2)
    }
    
    func getWorkspaceItems2() -> [WorkspaceItem]? {
        guard let itemsData = object(forKey: Const.workspaceItems2) as? Data,
              let items = try? JSONDecoder().decode([WorkspaceItem].self, from: itemsData) else {
            return nil
        }
        return items
    }

    func getWorkspaceItems() -> [WorkspaceItem]? {
        guard let itemsData = object(forKey: Const.workspaceItems) as? Data,
              let items = try? JSONDecoder().decode([WorkspaceItem].self, from: itemsData) else {
            return nil
        }
        return items
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
        case workspaceItems2
    }

    func set(_ value: Any?, forKey defaultName: Const) {
        set(value, forKey: defaultName.rawValue)
    }

    func object(forKey defaultName: Const) -> Any? {
        object(forKey: defaultName.rawValue)
    }
}
