//
//  QuickActionsViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 04/07/2025.
//

import Foundation
import SwiftUI

class QuickActionsViewModel: ObservableObject {
    private var cachedIcons: [String: Data] = [:]
    @ObservedObject var observer = FocusedAppObserver()
    @Published var assignedAppsToPages: [AssignedAppsToPages] = []
    @Published var items: [ShortcutObject] = []
    @Published var sections: [Int: [ShortcutObject]] = [:]
    @Published var pages: Int = 1
    @Published var currentPage: Int = 1
    private let allItems: [ShortcutObject]
    
    init(items: [ShortcutObject], allItems: [ShortcutObject]) {
        self.items = items
        self.allItems = allItems
        self.assignedAppsToPages = UserDefaults.standard.get(key: .assignedAppsToSubpages) ?? []
        self.currentPage = UserDefaults.standard.get(key: .subitemCurrentPage) ?? 1
        self.pages = UserDefaults.standard.get(key: .subitemPages) ?? 1
        self.sections = [pages: items]
        
        if let activeApp = self.observer.focusedAppName,
           let pageToFocus = assignedAppsToPages.first(where: { $0.appPath.contains(activeApp) }) {
            currentPage = pageToFocus.page
        }
        self.items.enumerated().forEach { (index, _) in
            if self.items[index].page < 1 {
                self.items[index].page = 1
            }
        }
    }
    
    func object(for id: String) -> ShortcutObject? {
        (allItems + items).first { $0.id == id }
    }
    
    func object(path: String) -> ShortcutObject? {
        (allItems + items).first { $0.path == path }
    }
    
    func prevPage() {
        if currentPage > 1 {
            currentPage -= 1
        }
        UserDefaults.standard.store(currentPage, for: .subitemCurrentPage)
    }
    
    func nextPage() {
        if currentPage < pages {
            currentPage += 1
        }
        UserDefaults.standard.store(currentPage, for: .subitemCurrentPage)
    }
    
    func addPage() {
        pages = pages + 1
        currentPage = pages
        (0..<10).forEach { index in
            var item: ShortcutObject = .empty(for: index, page: currentPage)
            item.objects = (0..<5).map { .empty(for: $0) }
            items.append(item)
        }
        UserDefaults.standard.store(pages, for: .subitemPages)
        UserDefaults.standard.store(currentPage, for: .subitemCurrentPage)
    }
    
    func removePage(with number: Int) {
        guard pages > 1 else { return }
        items.removeAll { $0.page == number }
        assignedAppsToPages.removeAll(where: { $0.page == number })
        items.enumerated().forEach { (index, object) in
            if items[index].page > number {
                items[index].page -= 1
                items[index].index = index
            }
        }
        assignedAppsToPages.enumerated().forEach { (index, _) in
            if assignedAppsToPages[index].page > number {
                assignedAppsToPages[index].page -= 1
            }
        }
        if pages > 1 {
            pages -= 1
        }
        currentPage = pages
        UserDefaults.standard.store(pages, for: .subitemPages)
        UserDefaults.standard.store(currentPage, for: .subitemCurrentPage)
        UserDefaults.standard.store(assignedAppsToPages, for: .assignedAppsToSubpages)
    }
    
    func add(_ object: ShortcutObject, at newIndex: Int = 0) {
        let offset = newIndex + ((currentPage - 1) * 10)
        if let oldIndex = items.firstIndex(where: { $0.id == object.id && items[offset].title != "EMPTY" }) {
            let oldObject = items[offset]
            var tmp = object
            tmp.index = offset
            tmp.page = currentPage
            items[offset] = tmp
            
            if items[offset].objects == nil {
                items[offset].objects = (0..<5).map { .empty(for: $0) }
            }
            
            var tmp2 = oldObject
            tmp2.index = oldIndex
            items[oldIndex] = tmp2
            
            if items[oldIndex].objects == nil {
                items[oldIndex].objects = (0..<5).map { .empty(for: $0) }
            }
        } else {
            var objects: [ShortcutObject]?
            if let oldIndex = items.firstIndex(where: { $0.id == object.id }) {
                objects = items[oldIndex].objects
            }
            items.enumerated().forEach { (i, item) in
                if item.id == object.id {
                    items[i] = .empty(for: i, page: currentPage)
                    items[i].objects = (0..<5).map { .empty(for: $0) }
                }
            }
            let offset = newIndex + ((currentPage - 1) * 10)
            var tmp = object
            tmp.index = offset
            tmp.page = currentPage
            items[offset] = tmp
            if items[offset].objects == nil {
                items[offset].objects = objects ?? (0..<5).map { .empty(for: $0) }
            }
        }
    }
    
    func addSubitem(to itemId: String, item: ShortcutObject, at subIndex: Int) -> ShortcutObject? {
        if let index = items.firstIndex(where: { $0.id == itemId }), items[index].title != "EMPTY" {
            if items[index].objects == nil {
                items[index].objects = (0..<5).map { .empty(for: $0) }
            }
            items[index].objects?[subIndex] = item
            return items[index]
        } else {
            return nil
        }
    }
    
    func removeSubitem(from itemId: String, at subIndex: Int) -> ShortcutObject? {
        let offset = subIndex + ((currentPage - 1) * 10)
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].objects?[offset] = .empty(for: offset)
            return items[index]
        }
        return nil
    }
    
    func remove(at index: Int) -> ShortcutObject {
        let offset = index + ((currentPage - 1) * 10)
        items[offset] = .empty(for: offset, page: currentPage)
        items[offset].objects = (0..<5).map { .empty(for: $0) }
        return items[offset]
    }
    
    func replace(app path: String, to page: Int) {
        guard let index = assignedAppsToPages.firstIndex(where: { $0.page == page }) else {
//            connectionManager.localError = "No app assigned to \(page), can't replace."
//            connectionManager.showsLocalError = true
            return
        }
        assignedAppsToPages[index] = .init(page: page, appPath: path)
        if let alreadyAssignedSomwhereIndex = assignedAppsToPages.firstIndex(where: { $0.appPath == path && $0.page != page }) {
            assignedAppsToPages.remove(at: alreadyAssignedSomwhereIndex)
        }
        UserDefaults.standard.store(assignedAppsToPages, for: .assignedAppsToSubpages)
        self.pages = pages
    }
    
    func getAssigned(to page: Int) -> AssignedAppsToPages? {
        assignedAppsToPages.first(where: { $0.page == page })
    }
    
    func assign(app path: String, to page: Int) {
        if let assignedApp = assignedAppsToPages.first(where: { $0.appPath == path }) {
//            connectionManager.localError = "App already assigned to page \(assignedApp.page)"
//            connectionManager.showsLocalError = true
            return
        }
        assignedAppsToPages.append(.init(page: page, appPath: path))
        UserDefaults.standard.store(assignedAppsToPages, for: .assignedAppsToSubpages)
        self.pages = pages
    }
    
    func unassign(app path: String, from page: Int) {
        assignedAppsToPages = assignedAppsToPages.filter { $0.appPath != path && $0.page != page }
        UserDefaults.standard.store(assignedAppsToPages, for: .assignedAppsToSubpages)
        self.pages = pages
    }
    
    func getIcon(fromAppPath appPath: String?) -> Data? {
        guard let appPath else {
            return nil
        }
        let bundleURL = URL(fileURLWithPath: appPath)
        
        guard let bundle = Bundle(url: bundleURL) else {
            return nil
        }
        
        guard let iconFile = bundle.infoDictionary?["CFBundleIconFile"] as? String else {
            let icon = NSWorkspace.shared.icon(forFile: appPath)
            let resizedIcon = icon.resizedImage(newSize: .init(width: 96.0, height: 96.0))
            let fallbackIcon = try? resizedIcon.imageData(for: .png(scale: 0.2, excludeGPSData: false))
            return fallbackIcon
        }
        
        let iconName = (iconFile as NSString).deletingPathExtension
        let iconExtension = (iconFile as NSString).pathExtension.isEmpty ? "icns" : (iconFile as NSString).pathExtension
        
        guard let iconPath = bundle.path(forResource: iconName, ofType: iconExtension) else {
            return nil
        }
        let pngProps: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: 0.0
        ]
        guard let icon = NSImage(contentsOfFile: iconPath) else {
            return nil
        }
        let resized = icon.resizedImage(newSize: .init(width: 96.0, height: 96.0))
        guard let tiffData = resized.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: pngProps) else {
            return nil
        }
//        cachedIcons[appPath] = pngData
        
//        let sizeInMB = Double(pngData.count) / (1024.0 * 1024.0)
//        countMB += sizeInMB
//        print(String(format: "%.8f MB", countMB))
        
        return pngData
    }
}
