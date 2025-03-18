//
//  UserDefaults+Ext.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 14/03/2024.
//

import Foundation

public struct Pages: Codable {
    let pages: Int
}

extension UserDefaults {
    func storeWebItems(_ webItems: [ShortcutObject]) {
        guard let jsonData = try? JSONEncoder().encode(webItems) else {
            return
        }

        set(jsonData, forKey: Const.webItems)
    }

    func getWebItems() -> [ShortcutObject]? {
        guard let itemsData = object(forKey: Const.webItems) as? Data,
              let items = try? JSONDecoder().decode([ShortcutObject].self, from: itemsData) else {
            return nil
        }
        return items
    }
    
    func storePages(_ pagesCount: Int) {
        let pages = Pages(pages: pagesCount)
        guard let jsonData = try? JSONEncoder().encode(pages) else {
            return
        }

        set(jsonData, forKey: Const.pages)
    }

    func getPagesCount() -> Int? {
        guard let itemsData = object(forKey: Const.pages) as? Data,
              let pages = try? JSONDecoder().decode(Pages.self, from: itemsData) else {
            return nil
        }
        return pages.pages
    }
    
    func storeWorkspaceItems(_ workspaceItems: [WorkspaceItem]) {
        guard let jsonData = try? JSONEncoder().encode(workspaceItems) else {
            return
        }

        set(jsonData, forKey: Const.workspaceItems)
    }
    
    func storeShortcutsItems(_ shortcuts: [ShortcutObject]) {
        guard let jsonData = try? JSONEncoder().encode(shortcuts) else {
            return
        }

        set(jsonData, forKey: Const.shortcuts)
    }

    func getWorkspaceItems() -> [WorkspaceItem]? {
        guard let itemsData = object(forKey: Const.workspaceItems) as? Data,
              let items = try? JSONDecoder().decode([WorkspaceItem].self, from: itemsData) else {
            return nil
        }
        return items
    }
    
    func getShortcutsItems() -> [ShortcutObject]? {
        guard let itemsData = object(forKey: Const.shortcuts) as? Data,
              let items = try? JSONDecoder().decode([ShortcutObject].self, from: itemsData) else {
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
        case shortcuts
        case pages
    }

    func set(_ value: Any?, forKey defaultName: Const) {
        set(value, forKey: defaultName.rawValue)
    }

    func object(forKey defaultName: Const) -> Any? {
        object(forKey: defaultName.rawValue)
    }
}
