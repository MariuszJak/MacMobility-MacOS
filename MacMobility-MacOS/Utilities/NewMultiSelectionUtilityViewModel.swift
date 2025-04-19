//
//  NewMultiSelectionUtilityViewModel.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 20/03/2025.
//

import Foundation
import SwiftUI

class NewMultiSelectionUtilityViewModel: ObservableObject {
    let allObjects: [ShortcutObject]
    var id: String?
    @Published var title: String = ""
    @Published var selectedIcon: NSImage? = NSImage(named: "multiapp")
    @Published var iconData: Data?
    @Published var configuredShortcuts: [ShortcutObject] = []
    @Published var shortcuts: [ShortcutObject] = []
    @Published var installedApps: [ShortcutObject] = []
    @Published var webpages: [ShortcutObject] = []
    @Published var utilities: [ShortcutObject] = []
    @Published var showTitleOnIcon: Bool = true
    var close: () -> Void = {}
    
    init(allObjects: [ShortcutObject]) {
        self.allObjects = allObjects
        self.shortcuts = allObjects.filter { $0.type == .shortcut }
        self.installedApps = allObjects.filter { $0.type == .app }
        self.webpages = allObjects.filter { $0.type == .webpage }
        self.utilities = allObjects.filter { $0.type == .utility }
    }
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
    }
    
    func objectAt(index: Int) -> ShortcutObject? {
        configuredShortcuts.first(where: { $0.index == index })
    }
    
    func object(for id: String) -> ShortcutObject? {
        shortcuts.first { $0.id == id } ?? installedApps.first { $0.id == id } ?? webpages.first { $0.id == id } ?? utilities.first { $0.id == id }
    }
    
    func removeShortcut(id: String) {
        configuredShortcuts.removeAll { $0.id == id }
    }
    
    func removeWebItem(id: String) {
        webpages.removeAll { $0.id == id }
        configuredShortcuts.removeAll { $0.id == id }
    }
    
    func removeUtilityItem(id: String) {
        utilities.removeAll { $0.id == id }
        configuredShortcuts.removeAll { $0.id == id }
    }
    
    func addConfiguredShortcut(object: ShortcutObject) {
        guard object.id != self.id else { return }
        if let index = configuredShortcuts.firstIndex(where: { $0.index == object.index && $0.page == object.page }) {
            let oldObject = configuredShortcuts[index]
            configuredShortcuts[index] = object
            configuredShortcuts.enumerated().forEach { (index, shortcut) in
                if (object.index != shortcut.index && shortcut.id == object.id) {
                    configuredShortcuts[index] = .init(
                        type: oldObject.type,
                        page: oldObject.page,
                        index: configuredShortcuts[index].index,
                        path: oldObject.path,
                        id: oldObject.id,
                        title: oldObject.title,
                        color: oldObject.color,
                        faviconLink: oldObject.faviconLink,
                        browser: oldObject.browser,
                        imageData: oldObject.imageData,
                        scriptCode: oldObject.scriptCode,
                        utilityType: oldObject.utilityType
                    )
                }
            }
        } else {
            configuredShortcuts = configuredShortcuts.filter { $0.id != object.id }
            configuredShortcuts.append(object)
        }
    }
    
    func saveWebpage(with webpageItem: ShortcutObject) {
        if let index = webpages.firstIndex(where: { $0.id == webpageItem.id }) {
            webpages[index] = webpageItem
            if let configuredIndex = configuredShortcuts.firstIndex(where: { $0.id == webpageItem.id }) {
                configuredShortcuts[configuredIndex] = .init(
                    type: webpageItem.type,
                    page: webpageItem.page,
                    index: configuredShortcuts[configuredIndex].index,
                    path: webpageItem.path,
                    id: webpageItem.id,
                    title: webpageItem.title,
                    color: webpageItem.color,
                    faviconLink: webpageItem.faviconLink,
                    browser: webpageItem.browser,
                    imageData: webpageItem.imageData
                )
            }
        } else {
            webpages.insert(webpageItem, at: 0)
        }
    }
    
    func saveUtility(with utilityItem: ShortcutObject) {
        if let index = utilities.firstIndex(where: { $0.id == utilityItem.id }) {
            utilities[index] = utilityItem
            if let configuredIndex = configuredShortcuts.firstIndex(where: { $0.id == utilityItem.id }) {
                configuredShortcuts[configuredIndex] = .init(
                    type: utilityItem.type,
                    page: utilityItem.page,
                    index: configuredShortcuts[configuredIndex].index,
                    path: utilityItem.path,
                    id: utilityItem.id,
                    title: utilityItem.title,
                    color: utilityItem.color,
                    faviconLink: utilityItem.faviconLink,
                    browser: utilityItem.browser,
                    imageData: utilityItem.imageData,
                    scriptCode: utilityItem.scriptCode,
                    utilityType: utilityItem.utilityType
                )
                UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
            }
        } else {
            utilities.insert(utilityItem, at: 0)
        }
    }
}
