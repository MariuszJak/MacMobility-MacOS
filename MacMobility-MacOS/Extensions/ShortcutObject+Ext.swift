//
//  ShortcutObject+Ext.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import SwiftUI

extension UtilityObject.UtilityType {
    func toAutomationType() -> AutomationType {
        switch self {
        case .commandline:
            return .bash
        case .multiselection:
            return .bash
        case .automation:
            return .automator
        case .macro:
            return .bash
        case .html:
            return .bash
        }
    }
}

extension ShortcutObject {
    static func from(script: AutomationScript, at index: Int? = nil) -> ShortcutObject {
        var utilityType: UtilityObject.UtilityType?
        var imageData = script.imageData
        switch script.type {
        case .automator, .none:
            utilityType = .automation
        case .bash:
            utilityType = .commandline
        case .html:
            utilityType = .html
        }
        var color: String?
        if script.script.contains("FILE_CONVERTER") {
            color = .convert
        }
        if script.script.contains("raycast://") {
            color = .raycast
            if imageData == nil {
                imageData = NSImage(named: "raycastIcon")?.toData
            }
        }
        if script.name == "MOV to MP4" || script.name == "MP4 to MOV" {
            color = "test"
        }
        return .init(
            type: utilityType == .html ? .html : .utility,
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
            showTitleOnIcon: script.showsTitle ?? (color != nil),
            category: script.category
        )
    }
}

