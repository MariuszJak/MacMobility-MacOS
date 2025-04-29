//
//  ShortcutObject+Ext.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import SwiftUI

extension ShortcutObject {
    static func from(script: AutomationScript, at index: Int? = nil) -> ShortcutObject {
        var utilityType: UtilityObject.UtilityType?
        switch script.type {
        case .automator, .none:
            utilityType = .automation
        case .bash:
            utilityType = .commandline
        }
        return .init(
            type: .utility,
            page: 1,
            index: index,
            path: nil,
            id: script.id.uuidString,
            title: script.name,
            color: nil,
            faviconLink: nil,
            browser: nil,
            imageData: script.imageData,
            scriptCode: script.script,
            utilityType: utilityType,
            objects: nil,
            showTitleOnIcon: false,
            category: script.category
        )
    }
}

