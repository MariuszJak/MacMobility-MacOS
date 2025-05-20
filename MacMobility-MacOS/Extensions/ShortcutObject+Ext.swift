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
        var imageData = script.imageData
        switch script.type {
        case .automator, .none:
            utilityType = .automation
        case .bash:
            utilityType = .commandline
        }
        var color: String?
        if script.script.contains("FILE_CONVERTER") {
            color = .convert
        }
        if script.script.contains("raycast://") {
            color = .raycast
            imageData = NSImage(named: "raycastIcon")?.toData
        }
        if script.name == "MOV to MP4" || script.name == "MP4 to MOV" {
            color = "test"
        }
        return .init(
            type: .utility,
            page: 1,
            index: index,
            path: nil,
            id: script.id.uuidString,
            title: script.name,
            color: color,
            faviconLink: nil,
            browser: nil,
            imageData: imageData,
            scriptCode: script.script,
            utilityType: utilityType,
            objects: nil,
            showTitleOnIcon: color != nil,
            category: script.category
        )
    }
}

