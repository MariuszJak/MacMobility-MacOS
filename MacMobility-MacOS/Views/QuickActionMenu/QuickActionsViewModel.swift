//
//  QuickActionsViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 04/07/2025.
//

import Foundation
import SwiftUI
import Combine

class QuickActionsViewModel: ObservableObject {
    private var cachedIcons: [String: Data] = [:]
    @ObservedObject var observer = FocusedAppObserver()
    @Published var hoveredIndex: Int? = nil
    @Published var hoveredSubIndex: Int? = nil
    @Published var assignedAppsToPages: [AssignedAppsToPages] = []
    @Published var items: [ShortcutObject] = []
    @Published var sections: [Int: [ShortcutObject]] = [:]
    @Published var pages: Int = 1
    @Published var currentPage: Int = 1
    @Published var showPopup = false
    @Published var submenuDegrees = 0.0
    @Published var subitem: ShortcutObject?
    @Published var isEditing: Bool = false
    public let action: (ShortcutObject) -> Void
    public var isTabPressed = false
    private let allItems: [ShortcutObject]
    private var lastDirectionChange: Date = .distantPast
    private let throttleInterval: TimeInterval = 0.4
    private var responder = HotKeyResponder.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(items: [ShortcutObject], allItems: [ShortcutObject], action: @escaping (ShortcutObject) -> Void) {
        self.items = items
        self.allItems = allItems
        self.action = action
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
        self.binding()
    }
    
    private func binding() {
        responder
            .$isEnterPressed
            .sink { [weak self] value in
                guard let self, !isEditing else { return }
                if !isTabPressed {
                    if let index = hoveredIndex, value {
                        let tmpIndex = index + ((currentPage - 1) * 10)
                        let item = self.items[tmpIndex]
                        if item.title != "EMPTY" {
                            action(item)
                        }
                    }
                } else {
                    guard let hoveredSubIndex,
                          let subitem,
                          let item = subitem.objects?[hoveredSubIndex],
                          value else {
                        return
                    }
                    action(item)
                }
            }
            .store(in: &cancellables)
        
        responder
            .$isTabPressed
            .sink { [weak self] value in
                guard let self, !isEditing else { return }
                guard let index = self.hoveredIndex else {
                    isTabPressed = false
                    showPopup = false
                    return
                }
                let tmpIndex = index + ((currentPage - 1) * 10)
                let item = self.items[tmpIndex]
                let subitems = (item.objects ?? []).filter { $0.title != "EMPTY" }
                guard item.title != "EMPTY" && subitems.count > 0 else {
                    isTabPressed = false
                    showPopup = false
                    return
                }
                let angle = Angle.degrees(Double(index) / Double(10) * 360)
                submenuDegrees = angle.degrees - 92
                subitem = item
                isTabPressed.toggle()
                showPopup.toggle()
                if isTabPressed {
                    hoveredSubIndex = 2
                }
            }
            .store(in: &cancellables)
        
        responder
            .$lastArrow
            .sink { [weak self] value in
                guard let value, let self,!isEditing else { return }
                if !isTabPressed {
                    handleArrowsForMainMenu(value)
                } else {
                    handleArrowsForSubMenu(value)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleArrowsForMainMenu(_ direction: HotKeyResponder.ArrowKey) {
        switch direction {
        case .left:
            self.prevPage()
        case .right:
            self.nextPage()
        case .up:
            if hoveredIndex == nil {
                hoveredIndex = 3
            } else {
                hoveredIndex! += 1
                if hoveredIndex! > 9 {
                    hoveredIndex = 0
                }
            }
        case .down:
            if hoveredIndex == nil {
                hoveredIndex = 0
            } else {
                hoveredIndex! -= 1
                if hoveredIndex! < 0 {
                    hoveredIndex = 9
                }
            }
        }
    }
    
    private func handleArrowsForSubMenu(_ direction: HotKeyResponder.ArrowKey) {
        switch direction {
        case .left, .right:
            break
        case .up:
            if hoveredSubIndex == nil {
                hoveredSubIndex = 2
            } else {
                hoveredSubIndex! += 1
                if hoveredSubIndex! > 4 {
                    hoveredSubIndex = 0
                }
            }
        case .down:
            if hoveredSubIndex == nil {
                hoveredSubIndex = 2
            } else {
                hoveredSubIndex! -= 1
                if hoveredSubIndex! < 0 {
                    hoveredSubIndex = 4
                }
            }
        }
    }
    
    func handleDirection(_ direction: EventDirection) {
        let now = Date()
        guard now.timeIntervalSince(lastDirectionChange) > throttleInterval else {
            return
        }
        lastDirectionChange = now
        
        switch direction {
        case .left:
            nextPage()
        case .right:
            prevPage()
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
        } else {
            currentPage = pages
        }
        UserDefaults.standard.store(currentPage, for: .subitemCurrentPage)
    }
    
    func nextPage() {
        if currentPage < pages {
            currentPage += 1
        } else {
            currentPage = 1
        }
        UserDefaults.standard.store(currentPage, for: .subitemCurrentPage)
    }
    
    func set(page number: Int) {
        currentPage = number
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
        // This replaces two apps with each other
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
            // This adds new one
            var objects: [ShortcutObject]?
            if let oldIndex = items.firstIndex(where: { $0.id == object.id && $0.page == currentPage }) {
                objects = items[oldIndex].objects
            }
            items.enumerated().forEach { (i, item) in
                if item.id == object.id && item.page == currentPage {
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
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].objects?[subIndex] = .empty(for: subIndex)
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
