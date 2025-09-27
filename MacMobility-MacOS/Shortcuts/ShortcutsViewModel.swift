//
//  ShortcutsViewModel.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 16/03/2025.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
import MultipeerConnectivity

import Foundation
import Network
import ScreenCaptureKit
import CoreImage
import CoreGraphics

struct AssignedAppsToPages: Codable {
    var page: Int
    let appPath: String
}

struct NeighboringIndexes {
    let page: Int
    let indexes: [Int]
    let conflict: Bool
}

struct PageAndIndex {
    let page: Int
    let index: Int
}

public class ShortcutsViewModel: ObservableObject, WebpagesWindowDelegate, UtilitiesWindowDelegate, JSONLoadable, ScriptExecutable {
    @Published var connectionManager: ConnectionManager
    @Published var pairingStatus: PairingStatus = .notPaired
    @Published var availablePeerWithName: (MCPeerID?, String)?
    @Published var connectedPeerName: String?
    @Published var configuredShortcuts: [ShortcutObject] = []
    @Published var shortcuts: [ShortcutObject] = []
    @Published var installedApps: [ShortcutObject] = []
    @Published var appsAddedByUser: [ShortcutObject] = []
    @Published var webpages: [ShortcutObject] = []
    @Published var quickActionItems: [ShortcutObject] = []
    @Published var searchText: String = ""
    @Published var cancellables = Set<AnyCancellable>()
    @Published var pages = 1
    @Published var scrollToApp: String = " "

    @Published var scrollToPage: Int = 0
    @Published var availablePeerName: String = ""
    @Published var sections: [ShortcutSection] = []
    @Published var allSectionsExpanded = true
    @Published var streamConnectionState: StreamConnectionState = .notConnected
    @Published var displayID: CGDirectDisplayID?
    @Published var showDependenciesView: Bool = false
    @Published var dependenciesObjects: [DependencyObject] = []
    @Published var idOfObjectToReplaceDependencies: String = ""
    @Published var draggingData: DraggingData = .init(size: nil)
    @Published var currentlyTargetedIndex: PageAndIndex?
    @Published var affectedIndexes: NeighboringIndexes = .init(page: 0, indexes: [], conflict: false)
    @Published var utilities: [ShortcutObject] = [] {
        didSet {
            sections = utilitiesWithSections()
        }
    }
    var dependencyUpdate: ([String]) -> Void = { _ in }
    var close: () -> Void = {}
    private var timer: Timer?
    public var testColor = "#6DDADE"
    private var allWebpages: [ShortcutObject] = []
    private var cachedIcons: [String: Data] = [:]
    private var tmpAllItems: [ShortcutObject] = []
    private var setupMode: SetupMode?
    private var websites: [WebsiteTest] = []
    private var automations: AutomationsList?
    private var createMultiactions: Bool?
    private var browser: Browsers?
    private var installedAllApps: [ShortcutObject] = []
    
    
    init(connectionManager: ConnectionManager) {
//        UserDefaults.standard.clear(key: .quickActionItems)
//        UserDefaults.standard.clear(key: .subitemPages)
//        UserDefaults.standard.clear(key: .utilities)
//        UserDefaults.standard.clearAll()
        self.connectionManager = connectionManager
        self.configuredShortcuts = UserDefaults.standard.get(key: .shortcuts) ?? []
        self.webpages = UserDefaults.standard.get(key: .webItems) ?? []
        self.utilities = UserDefaults.standard.get(key: .utilities) ?? []
        self.pages = UserDefaults.standard.get(key: .pages) ?? 1
        self.appsAddedByUser = UserDefaults.standard.get(key: .userApps) ?? []
        self.quickActionItems = UserDefaults.standard.get(key: .quickActionItems) ?? (0..<10).map { .empty(for: $0, page: 1) }
        if self.quickActionItems.isEmpty {
            self.quickActionItems = (0..<10).map { .empty(for: $0, page: 1) }
        }
        self.automations = loadJSON("automations")
        connectionManager.assignedAppsToPages = UserDefaults.standard.get(key: .assignedAppsToPages) ?? []
        fetchShortcuts()
        fetchInstalledApps()
        registerListener()
        startMonitoring()
        migrateConfiguredShortcuts()
            
        $currentlyTargetedIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pageAndIndex in
                guard let self, let pageAndIndex, let indexes = neighboringIndexesWithConflict(for: pageAndIndex.index, page: pageAndIndex.page, size: draggingData.size) else { return }
                affectedIndexes = indexes
//                print("View model update: page -> \(pageAndIndex.page), index -> \(pageAndIndex.index), affectedIndexes -> \(affectedIndexes)")
            }
            .store(in: &cancellables)
        
        connectionManager
            .$pairingStatus
            .assign(to: \.pairingStatus, on: self)
            .store(in: &cancellables)
        
        connectionManager
            .$availablePeerWithName
            .assign(to: \.availablePeerWithName, on: self)
            .store(in: &cancellables)
        
        connectionManager
            .$connectedPeerName
            .assign(to: \.connectedPeerName, on: self)
            .store(in: &cancellables)
        
        quickActionItems.enumerated().forEach { (index, item) in
            if item.objects == nil {
                quickActionItems[index].objects = (0..<5).map { .empty(for: $0) }
            }
        }
        
        connectionManager
            .$streamConnectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.streamConnectionState = value
            }
            .store(in: &cancellables)
        
        connectionManager
            .$displayID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.displayID = value
            }
            .store(in: &cancellables)
        
        dependencyUpdate = { updates in
            self.updateDependenciesOfObject(with: self.idOfObjectToReplaceDependencies, replacements: updates)
        }
        runInitialScriptsIfNeeded()
    }
    
    func migrateConfiguredShortcuts() {
        configuredShortcuts.enumerated().forEach { (index, object) in
            if object.size == nil {
                configuredShortcuts[index].size = .init(width: 1, height: 1)
            }
        }
    }
    
    func runInitialScriptsIfNeeded() {
        configuredShortcuts.enumerated().forEach { (index, object) in
            if object.type == .control, let initialScript = object.color, !initialScript.contains("INITIAL") {
                if let executedResult = execute(script: initialScript) {
                    configuredShortcuts[index].color = "INITIAL:\(executedResult)"
                    connectionManager.shortcuts = configuredShortcuts
                }
            }
        }
    }
    
    func saveQuickActionItems(_ items: [ShortcutObject]) {
        self.quickActionItems = items
        UserDefaults.standard.store(quickActionItems, for: .quickActionItems)
    }
    
    func replace(app path: String, to page: Int) {
        guard let index = connectionManager.assignedAppsToPages.firstIndex(where: { $0.page == page }) else {
            connectionManager.localError = "No app assigned to \(page), can't replace."
            connectionManager.showsLocalError = true
            return
        }
        connectionManager.assignedAppsToPages[index] = .init(page: page, appPath: path)
        if let alreadyAssignedSomwhereIndex = connectionManager.assignedAppsToPages.firstIndex(where: { $0.appPath == path && $0.page != page }) {
            connectionManager.assignedAppsToPages.remove(at: alreadyAssignedSomwhereIndex)
        }
        UserDefaults.standard.store(connectionManager.assignedAppsToPages, for: .assignedAppsToPages)
        self.pages = pages
    }
    
    func assign(app path: String, to page: Int) {
        if let assignedApp = connectionManager.assignedAppsToPages.first(where: { $0.appPath == path }) {
            connectionManager.localError = "App already assigned to page \(assignedApp.page)"
            connectionManager.showsLocalError = true
            return
        }
        connectionManager.assignedAppsToPages.append(.init(page: page, appPath: path))
        UserDefaults.standard.store(connectionManager.assignedAppsToPages, for: .assignedAppsToPages)
        self.pages = pages
    }
    
    func unassign(app path: String, from page: Int) {
        connectionManager.assignedAppsToPages = connectionManager.assignedAppsToPages.filter { $0.appPath != path && $0.page != page }
        UserDefaults.standard.store(connectionManager.assignedAppsToPages, for: .assignedAppsToPages)
        self.pages = pages
    }
    
    func getAssigned(to page: Int) -> AssignedAppsToPages? {
        connectionManager.assignedAppsToPages.first(where: { $0.page == page })
    }
    
    func extendScreen() {
        Task {
            await connectionManager.extendScreen()
        }
    }
    
    func allCategories() -> [String] {
        utilities.compactMap { $0.category }.removingDuplicates()
    }
    
    func utilitiesWithSections(removeId: String? = nil) -> [ShortcutSection] {
        removeFromSections(with: removeId)
        utilities.forEach { so in
            if sections.contains(where: { $0.title.lowercased() == so.category?.lowercased() }) {
                if let index = sections.firstIndex(where: { $0.title.lowercased() == so.category?.lowercased() }) {
                    if !sections[index].items.contains(where: { $0.id == so.id }) {
                        sections[index].items.append(so)
                    } else {
                        if let itemIndex = sections[index].items.firstIndex(where: { $0.id == so.id }) {
                            sections[index].items[itemIndex] = so
                        }
                    }
                }
            } else if let category = so.category {
                let title = category.isEmpty ? "Other" : category
                if sections.contains(where: { $0.title.lowercased() == title.lowercased() }) {
                    if let index = sections.firstIndex(where: { $0.title.lowercased() == title.lowercased() }) {
                        if !sections[index].items.contains(where: { $0.id == so.id }) {
                            sections[index].items.append(so)
                        }
                    }
                } else {
                    sections.insert(.init(title: title, isExpanded: true, items: [so]), at: 0)
                }
            }
        }
        sections.forEach { section in
            section.items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        
        return sections.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
    
    func removeFromSections(with removeId: String?) {
        guard let removeId else { return }
        sections.enumerated().forEach { sectionIndex, section in
            section.items.enumerated().forEach { itemIndex, item in
                if item.id == removeId {
                    sections[sectionIndex].items.remove(at: itemIndex)
                    if sections[sectionIndex].items.isEmpty {
                        sections.remove(at: sectionIndex)
                    }
                }
            }
        }
    }
    
    func toggleAllSections() {
        var tmp: [ShortcutSection] = []
        allSectionsExpanded.toggle()
        
        sections.forEach {
            $0.isExpanded = allSectionsExpanded
            tmp.append($0)
        }
        sections = tmp
    }
    
    func toggleCollapseForSection(for title: String) {
        if let index = sections.firstIndex(where: { $0.title.lowercased() == title.lowercased() }) {
            sections[index].isExpanded.toggle()
        }
        utilities = UserDefaults.standard.get(key: .utilities) ?? []
    }
    
    func expandSectionIfNeeded(for title: String) {
        if let index = sections.firstIndex(where: { $0.title.lowercased() == title.lowercased() }) {
            if !sections[index].isExpanded {
                sections[index].isExpanded.toggle()
            }
        }
        utilities = UserDefaults.standard.get(key: .utilities) ?? []
    }
    
    func registerListener() {
        $searchText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                guard let self else { return }
                if text.isEmpty {
                    self.tmpAllItems.removeAll()
                } else {
                    tmpAllItems.appendUnique(contentsOf: installedApps + shortcuts + webpages + utilities + appsAddedByUser)
                }
                self.fetchShortcuts()
                self.fetchInstalledApps()
                self.searchWebpages()
                self.searchUtilities()
            }
            .store(in: &cancellables)
        
        connectionManager.$browser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] browser in
                if let browser {
                    self?.browser = browser
                    UserDefaults.standard.store(browser, for: .browser)
                }
            }
            .store(in: &cancellables)
        
        connectionManager.$createMultiactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] createMultiactions in
                self?.createMultiactions = createMultiactions
            }
            .store(in: &cancellables)
        
        connectionManager.$initialSetup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] setupMode in
                self?.setupMode = setupMode
            }
            .store(in: &cancellables)
        
        connectionManager.$websites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] websites in
                self?.websites = websites
            }
            .store(in: &cancellables)
        
        connectionManager.$automatedActions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] options in
                self?.handleAutomatedActions(options)
            }
            .store(in: &cancellables)
        
        connectionManager.$dynamicUrls
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (browser, urls) in
                if !urls.isEmpty {
                    self?.addSafariURLsToMultiactions(urls: urls, browser: browser)
                }
            }
            .store(in: &cancellables)
    }
    
    func addSafariURLsToMultiactions(urls: [String], browser: Browsers) {
        var websitesSO: [ShortcutObject] = []
        let name = urls.extractWebsiteNames().joined(separator: ", ")
        urls.enumerated().forEach { (index, url) in
            let so: ShortcutObject = .init(type: .webpage, page: 1, index: index, indexes: [index], path: url, id: UUID().uuidString, title: "", color: nil, faviconLink: nil, browser: browser, imageData: nil, scriptCode: nil, utilityType: nil, objects: nil, showTitleOnIcon: false)
            if !webpages.contains(where: { $0.browser == so.browser && $0.path == so.path }) {
                saveWebpage(with: so)
            }
            websitesSO.append(so)
        }
        let ma: ShortcutObject = .init(type: .utility, page: 1, index: 0, indexes: [0], path: nil, id: UUID().uuidString, title: name, color: nil, faviconLink: nil, browser: nil, imageData: NSImage(named: "multiapp")?.toData, scriptCode: nil, utilityType: .multiselection, objects: websitesSO, showTitleOnIcon: true, category: "Multiselection")
        saveUtility(with: ma)
    }
    
    func isAppAddedByUser(path: String) -> Bool {
        appsAddedByUser.contains(where: { $0.path == path })
    }
    
    func appHasAutomation(path: String) -> AutomationItem? {
        guard let name = path.appNameFromPath() else {
            return nil
        }
        if let automation = automations?.automations.first(where: { $0.title.replacingOccurrences(of: " (Raycast)", with: "").lowercased() == name.lowercased() }) {
            return automation
        }
        return nil
    }
    
    func removeAppInstalledByUser(path: String) {
        appsAddedByUser = appsAddedByUser.filter { $0.path != path }
        installedApps = installedApps.filter { $0.path != path }
        configuredShortcuts.removeAll { $0.path == path }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
        UserDefaults.standard.store(appsAddedByUser, for: .userApps)
    }
    
    func handleAutomatedActions(_ options: [AutomationOption]?) {
        guard let options, let setupMode else {
            return
        }
        
        let volumeControl: ShortcutObject = .init(type: .control, page: 1, index: 0, indexes: [0, 1, 2], size: .init(width: 3, height: 1), path: "", id: "horizontal-scroll4", title: "Volume Control", color: nil, faviconLink: nil, browser: nil, imageData: nil, scriptCode: "osascript -e \"set volume output volume %d\"", utilityType: .commandline, objects: nil, showTitleOnIcon: false, category: "Experimental")
        addConfiguredShortcut(object: volumeControl)
        
        options.forEach { option in
            addAutomations(
                from: setupMode.type == .advanced
                ? option.scripts
                : option.scripts.filter { !($0.isAdvanced ?? false) }
            )
            if option.title == "macOS System" {
                let filtered = setupMode.type == .advanced
                ? option.scripts
                : option.scripts.filter { !($0.isAdvanced ?? false) }
                var i: Int = 3
                
                filtered.enumerated().forEach { (index, script) in
                    if script.script.contains("URLs"), let browser {
                        if script.script.contains(browser.name.uppercased()) {
                            let so: ShortcutObject = .from(script: script, at: i)
                            addConfiguredShortcut(object: so)
                            i += 1
                        }
                    } else {
                        if !script.script.contains("URLs") {
                            let so: ShortcutObject = .from(script: script, at: i)
                            addConfiguredShortcut(object: so)
                            i += 1
                        }
                    }
                }
                var websitesSO: [ShortcutObject] = []
                websites.forEach { website in
                    if website.url.containsValidDomain {
                        let updatedURL = website.url.applyHTTPS()
                        let so: ShortcutObject = .init(
                            type: .webpage, page: 1, index: i, indexes: [i], path: updatedURL, id: UUID().uuidString,
                            title: "", color: nil, faviconLink: nil, browser: browser ?? .safari, imageData: website.nsImage?.toData,
                            scriptCode: nil, utilityType: nil, objects: nil, showTitleOnIcon: false
                        )
                        saveWebpage(with: so)
                        addConfiguredShortcut(object: so)
                        websitesSO.append(so)
                        i += 1
                    }
                }
                if let createMultiactions, createMultiactions {
                    websitesSO.enumerated().forEach { (index, _) in
                        websitesSO[index].index = index
                        websitesSO[index].indexes = [index]
                    }
                    let ma: ShortcutObject = .init(
                        type: .utility, page: 1, index: i, indexes: [i], path: nil, id: UUID().uuidString,
                        title: "", color: nil, faviconLink: nil, browser: nil, imageData: NSImage(named: "multiapp")?.toData,
                        scriptCode: nil, utilityType: .multiselection, objects: websitesSO, showTitleOnIcon: false,
                        category: "Multiselection"
                    )
                    saveUtility(with: ma)
                    addConfiguredShortcut(object: ma)
                }
            }
        }
    }
    
    func objectAt(index: Int, page: Int) -> ShortcutObject? {
        configuredShortcuts.filter { $0.page == page }.first(where: { $0.indexes?.first == index })
    }
    
    func shouldDisplayPlusAt(index: Int, page: Int) -> ShortcutObject? {
        configuredShortcuts.filter { $0.page == page }.first(where: { $0.indexes?.contains(index) ?? false })
    }
    
    func object(for id: String, index: Int, page: Int) -> ShortcutObject? {
        var item: ShortcutObject?
        if searchText.isEmpty {
            item = shortcuts.first { $0.id == id } ?? installedApps.first { $0.id == id } ?? webpages.first { $0.id == id } ?? utilities.first { $0.id == id }
        } else {
            item = tmpAllItems.first { $0.id == id }
        }
        guard let item else { return nil }
        
        if item.type == .control || item.size?.toItemSize != .size1x1 {
            guard let allIndexes = neighboringIndexes(for: index, size: item.size) else {
                return nil
            }
            let configuredIndexes = configuredShortcuts.filter { $0.page == page && $0.id != id }.compactMap { $0.indexes }.flatMap { $0 }
            let intersects = Set(allIndexes).intersection(Set(configuredIndexes))
            return intersects.isEmpty ? item : nil
        } else {
            guard neighboringIndexes(for: index, size: item.size) != nil else {
                return nil
            }
            let configuredIndexes = configuredShortcuts.filter { $0.page == page && ($0.type == .control || $0.size?.toItemSize != .size1x1) }.compactMap { $0.indexes }.flatMap { $0 }
            return configuredIndexes.contains(index) ? nil : item
        }
    }
    
    func app(for id: String) -> ShortcutObject? {
        if searchText.isEmpty {
            installedApps.first { $0.id == id }
        } else {
            tmpAllItems.filter { $0.type == .app }.first { $0.id == id }
        }
    }
    
    func allObjects() -> [ShortcutObject] {
        shortcuts + installedApps + webpages + utilities + appsAddedByUser
    }
    
    func removeShortcut(id: String, page: Int) {
//        configuredShortcuts.removeAll { $0.id == id }
        configuredShortcuts.removeAll(where: { $0.page == page && $0.id == id })
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
    }
    
    func addPage() {
        pages += 1
        scrollToPage = pages
        UserDefaults.standard.store(pages, for: .pages)
    }
    
    func removePage(with number: Int) {
        connectionManager.assignedAppsToPages.removeAll { $0.page == number }
        configuredShortcuts.removeAll { $0.page == number }
        configuredShortcuts.enumerated().forEach { (index, object) in
            if configuredShortcuts[index].page > number {
                configuredShortcuts[index].page -= 1
            }
        }
        connectionManager.assignedAppsToPages.enumerated().forEach { (index, object) in
            if connectionManager.assignedAppsToPages[index].page > number {
                connectionManager.assignedAppsToPages[index].page -= 1
            }
        }
        if pages > 1 {
            pages -= 1
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
        UserDefaults.standard.store(pages, for: .pages)
        UserDefaults.standard.store(connectionManager.assignedAppsToPages, for: .assignedAppsToPages)
    }
    
    func exportPageAsAutomations(number: Int) {
        let pageContent = configuredShortcuts.filter { $0.page == number }
        let scripts: [AutomationScript] = pageContent.map { .init(id: UUID(), name: $0.title, description: "",
                                                                  script: $0.scriptCode ?? "", imageData: $0.imageData, imageName: nil,
                                                                  type: $0.utilityType?.toAutomationType(), isAdvanced: false, showsTitle: true, category: $0.category) }
        let list: AutomationsList = .init(automations: [.init(id: UUID(), title: "CHANGE_TITLE", description: "CHANGE_DESCRIPTION", imageData: nil, imageName: nil, scripts: scripts)])
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "automations.json"
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let data = try JSONEncoder().encode(list)
                    try data.write(to: url)
                } catch {
                    print("Failed to save JSON: \(error)")
                }
            }
        }
    }
    
    func removeWebItem(id: String) {
        webpages.removeAll { $0.id == id }
        configuredShortcuts.removeAll { $0.id == id }
        UserDefaults.standard.store(webpages, for: .webItems)
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
    }
    
    func removeUtilityItem(id: String) {
        utilities.removeAll { $0.id == id }
        configuredShortcuts.removeAll { $0.id == id }
        UserDefaults.standard.store(utilities, for: .utilities)
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
        sections = utilitiesWithSections(removeId: id)
    }
    
    func addAutomations(from scripts: [AutomationScript]) {
        let shortcuts: [ShortcutObject] = scripts.map { ShortcutObject.from(script: $0) }
        shortcuts.forEach { object in
            saveUtility(with: object)
        }
    }
    
    func addConfiguredShortcut(object: ShortcutObject, page: Int = 0) {
        if let index = configuredShortcuts.firstIndex(where: { !Set($0.indexes ?? []).intersection(Set(object.indexes ?? [])).isEmpty && $0.page == object.page }) {
            let oldObject = configuredShortcuts[index]
            configuredShortcuts[index] = object
            configuredShortcuts.enumerated().forEach { (index, shortcut) in
                if (object.indexes != shortcut.indexes && shortcut.id == object.id && shortcut.page == object.page) {
                    configuredShortcuts[index] = .init(
                        type: oldObject.type,
                        page: configuredShortcuts[index].page,
                        index: configuredShortcuts[index].index,
                        indexes: neighboringIndexes(for: configuredShortcuts[index].indexes?.first, size: oldObject.size),
                        size: oldObject.size ?? .init(width: 1, height: 1),
                        path: oldObject.path,
                        id: oldObject.id,
                        title: oldObject.title,
                        color: oldObject.color,
                        faviconLink: oldObject.faviconLink,
                        browser: oldObject.browser,
                        imageData: oldObject.imageData,
                        scriptCode: oldObject.scriptCode,
                        utilityType: oldObject.utilityType,
                        objects: oldObject.objects,
                        showTitleOnIcon: oldObject.showTitleOnIcon ?? true,
                        category: oldObject.category
                    )
                }
            }
        } else {
            if object.scriptCode?.contains("DEPENDENCY_") ?? false {
                dependenciesObjects = extractDependencies(from: object.scriptCode ?? "")
                if dependenciesObjects.contains(where: { $0.type == .tool }) {
                    if let toolLocation = dependenciesObjects.first?.tool {
                        if !isCLIToolInstalled(at: toolLocation) {
                            showDependenciesView = true
                        }
                    }
                    if dependenciesObjects.contains(where: { $0.type == .text }) && !showDependenciesView {
                        dependenciesObjects.removeAll(where: { $0.type == .tool })
                        idOfObjectToReplaceDependencies = object.id
                        showDependenciesView = true
                    }
                } else {
                    showDependenciesView = true
                    idOfObjectToReplaceDependencies = object.id
                }
            }
            configuredShortcuts.removeAll(where: { $0.page == page && $0.id == object.id })
            configuredShortcuts.append(object)
        }
        runInitialScriptsIfNeeded()
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
    }
    
    func checkAvailableSpace(
        for index: Int?,
        size: CGSize?,
        inGridWithColumns columns: Int = 7,
        rows: Int = 3
    ) -> ([Int], Bool)? {
        guard let index, let size else {
            return nil
        }
        let totalSquares = columns * rows
        let objectWidth = Int(size.width)
        let objectHeight = Int(size.height)

        let startRow = index / columns
        let startCol = index % columns

        var result: [Int] = []
        var outOfBounds: Bool = false
        for dy in 0..<objectHeight {
            for dx in 0..<objectWidth {
                let newRow = startRow + dy
                let newCol = startCol + dx
                if newCol >= columns || newRow >= rows {
                    continue
                }
                let newIndex = newRow * columns + newCol
                result.append(newIndex)
                
                outOfBounds = newIndex > totalSquares
            }
        }
        let outOfSpace = startCol + objectWidth > columns || startRow + objectHeight > rows

        return (result, (outOfBounds || outOfSpace))
    }
    
    func neighboringIndexesWithConflict(
        for index: Int?,
        page: Int,
        size: CGSize?,
        inGridWithColumns columns: Int = 7,
        rows: Int = 3
    ) -> NeighboringIndexes? {
        guard let availableSpace = checkAvailableSpace(for: index, size: size),
              let draggingIndexes = draggingData.indexes else {
            return nil
        }
        let neighboringIndexes = availableSpace.0
        let outOfBounds = availableSpace.1
        let configuredIndexes = configuredShortcuts.filter { $0.page == page }.compactMap { $0.indexes }.flatMap { $0 }
        let conflict = Set(configuredIndexes).subtracting(draggingIndexes).intersection(neighboringIndexes).isEmpty && !outOfBounds
        return .init(page: page, indexes: neighboringIndexes, conflict: !conflict)
    }
    
    func scaleObjectWithConflict(
        for index: Int?,
        page: Int,
        size: CGSize?,
        indexes: [Int],
        id: String? = nil,
        inGridWithColumns columns: Int = 7,
        rows: Int = 3
    ) -> NeighboringIndexes? {
        guard let availableSpace = checkAvailableSpace(for: index, size: size) else {
            return nil
        }
        let neighboringIndexes = availableSpace.0
        let outOfBounds = availableSpace.1
        
        let configuredIndexes = configuredShortcuts.filter { $0.page == page }.filter { $0.id != id }.compactMap { $0.indexes }.flatMap { $0 }
        let conflict = !(Set(indexes).intersection(configuredIndexes).isEmpty && !outOfBounds)
        return .init(page: page, indexes: neighboringIndexes, conflict: conflict)
    }
    
    func neighboringIndexes(
        for index: Int?,
        size: CGSize?,
        inGridWithColumns columns: Int = 7,
        rows: Int = 3,
        checkBoundries: Bool = true
    ) -> [Int]? {
        guard let index, let size else {
            return nil
        }
        let totalSquares = columns * rows
        let objectWidth = Int(size.width)
        let objectHeight = Int(size.height)

        let startRow = index / columns
        let startCol = index % columns

        // Check if the object would go out of bounds
        if checkBoundries, startCol + objectWidth > columns || startRow + objectHeight > rows {
            return nil
        }

        var result: [Int] = []

        for dy in 0..<objectHeight {
            for dx in 0..<objectWidth {
                let newRow = startRow + dy
                let newCol = startCol + dx
                let newIndex = newRow * columns + newCol

                // Additional safety check
                if !checkBoundries || newIndex < totalSquares {
                    result.append(newIndex)
                } else {
                    return nil
                }
            }
        }

        return result
    }
    
    func extractDependencies(from text: String) -> [DependencyObject] {
        var dependencies: [DependencyObject] = []
        
        let pattern = #"\[DEPENDENCY_(\d+):\s*\{([^}]*)\}\]"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in matches {
            guard match.numberOfRanges == 3 else { continue }
            let bodyRange = Range(match.range(at: 2), in: text)!
            let body = String(text[bodyRange])
            
            let jsonFormatted = "{\(body)}"
            do {
                if let jsonData = jsonFormatted.data(using: .utf8) {
                    let object = try JSONDecoder().decode(DependencyObject.self, from: jsonData)
                    dependencies.append(object)
                }
            } catch {
                print(error)
            }
        }
        
        return dependencies
    }
    
    func updateDependenciesOfObject(with id: String, replacements: [String]) {
        guard var object = configuredShortcuts.first(where: { $0.id == id }) else { return }
        replacements.enumerated().forEach { index, replacement in
            if !replacement.isEmpty {
                let split = replacement.split(separator: "&+$").map { String($0) }
                if let script = replaceDependency(in: object.scriptCode, id: split[safe: 0], with: split[safe: 1]) {
                    object.scriptCode = script
                }
            }
        }
        saveUtility(with: object)
    }
    
    func replaceDependency(in text: String?, id: String?, with replacement: String?) -> String? {
        guard let text, let id, let replacement else { return nil }
        let pattern = #"\[\#(id):\s*\{[^}]*\}\]"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }
    
    func isCLIToolInstalled(at path: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.isExecutableFile(atPath: path)
    }
    
    func searchWebpages() {
        webpages.enumerated().forEach { (index, webpage) in
            if searchText.isEmpty {
                webpages[index].scriptCode = ""
            } else {
                webpages[index].scriptCode = webpage.title.lowercased().contains(self.searchText.lowercased()) ? "" : "Hidden"
            }
        }
    }
    
    func searchUtilities() {
        utilities.enumerated().forEach { (index, utility) in
            if searchText.isEmpty {
                if !(utilities[index].path?.contains("control:") ?? false) {
                    utilities[index].path = ""
                }
            } else {
                utilities[index].path = (utility.title.lowercased().contains(self.searchText.lowercased()) ||
                                         utility.category?.lowercased().contains(self.searchText.lowercased()) ?? false) ? "" : "Hidden"
            }
        }
    }
    
    func fetchShortcuts() {
        shortcuts = getShortcutsList()
        configuredShortcuts.filter { $0.type == .shortcut }.forEach { configuredShortcut in
            guard self.searchText.isEmpty else { return }
            let shortcutExists = shortcuts.contains(where: { $0.id == configuredShortcut.id })
            if !shortcutExists {
                if let index = configuredShortcuts.firstIndex(where: { $0.id == configuredShortcut.id }) {
                    configuredShortcuts.remove(at: index)
                    connectionManager.shortcuts = configuredShortcuts
                    UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
                }
            }
        }
    }
    
    func saveWebpage(with webpageItem: ShortcutObject) {
        if let index = webpages.firstIndex(where: { $0.id == webpageItem.id }) {
            webpages[index] = webpageItem
            if let configuredIndex = configuredShortcuts.firstIndex(where: { $0.id == webpageItem.id }) {
                configuredShortcuts[configuredIndex] = .init(
                    type: webpageItem.type,
                    page: configuredShortcuts[configuredIndex].page,
                    index: configuredShortcuts[configuredIndex].index,
                    indexes: configuredShortcuts[configuredIndex].indexes,
                    size: configuredShortcuts[configuredIndex].size ?? .init(width: 1, height: 1),
                    path: webpageItem.path,
                    id: webpageItem.id,
                    title: webpageItem.title,
                    color: webpageItem.color,
                    faviconLink: webpageItem.faviconLink,
                    browser: webpageItem.browser,
                    imageData: webpageItem.imageData,
                    objects: webpageItem.objects,
                    showTitleOnIcon: webpageItem.showTitleOnIcon ?? true,
                    category: webpageItem.category
                )
                UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
            }
            let qamIndexes = quickActionItems.allIndexes(where: { $0.id == webpageItem.id })
            qamIndexes.forEach { index in
                quickActionItems[index] = .init(
                    type: webpageItem.type,
                    page: quickActionItems[index].page,
                    index: quickActionItems[index].index,
                    path: webpageItem.path,
                    id: webpageItem.id,
                    title: webpageItem.title,
                    color: webpageItem.color,
                    faviconLink: webpageItem.faviconLink,
                    browser: webpageItem.browser,
                    imageData: webpageItem.imageData,
                    scriptCode: webpageItem.scriptCode,
                    utilityType: webpageItem.utilityType,
                    objects: webpageItem.objects,
                    showTitleOnIcon: webpageItem.showTitleOnIcon ?? true,
                    category: webpageItem.category
                )
            }
            UserDefaults.standard.store(quickActionItems, for: .quickActionItems)
        } else {
            webpages.insert(webpageItem, at: 0)
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(webpages, for: .webItems)
    }
    
    func saveUtility(with utilityItem: ShortcutObject) {
        var canSave: Bool = true
        let configuredIndexes = configuredShortcuts.allIndexes(where: { $0.id == utilityItem.id })
        configuredIndexes.forEach { configuredIndex in
            let indexes = neighboringIndexes(for: configuredShortcuts[configuredIndex].index, size: utilityItem.size) ?? []
            if let neighboringIndexesWithConflict = scaleObjectWithConflict(
                for: configuredShortcuts[configuredIndex].index,
                page: configuredShortcuts[configuredIndex].page,
                size: utilityItem.size,
                indexes: indexes,
                id: utilityItem.id
            ) {
                if canSave {
                    canSave = !neighboringIndexesWithConflict.conflict
                }
            } else {
                canSave = false
            }
        }
        
        guard canSave else {
            connectionManager.localError = "Cannot save utility. Some other utility overlaps with this utility or it would go out of bounds."
            connectionManager.showsLocalError = true
            return
        }
        
        removeFromSections(with: utilityItem.id)
        if let index = utilities.firstIndex(where: { $0.id == utilityItem.id }) {
            utilities[index] = utilityItem
            let configuredIndexes = configuredShortcuts.allIndexes(where: { $0.id == utilityItem.id })
            configuredIndexes.forEach { configuredIndex in
                let indexes = neighboringIndexes(for: configuredShortcuts[configuredIndex].index, size: utilityItem.size)
                configuredShortcuts[configuredIndex] = .init(
                    type: utilityItem.type,
                    page: configuredShortcuts[configuredIndex].page,
                    index: configuredShortcuts[configuredIndex].index,
                    indexes: indexes,
                    size: utilityItem.size,
                    path: utilityItem.path,
                    id: utilityItem.id,
                    title: utilityItem.title,
                    color: utilityItem.color,
                    faviconLink: utilityItem.faviconLink,
                    browser: utilityItem.browser,
                    imageData: utilityItem.imageData,
                    scriptCode: utilityItem.scriptCode,
                    utilityType: utilityItem.utilityType,
                    objects: utilityItem.objects,
                    showTitleOnIcon: utilityItem.showTitleOnIcon ?? true,
                    category: utilityItem.category
                )
            }
            UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
            let qamIndexes = quickActionItems.allIndexes(where: { $0.id == utilityItem.id })
            qamIndexes.forEach { index in
                quickActionItems[index] = .init(
                    type: utilityItem.type,
                    page: quickActionItems[index].page,
                    index: quickActionItems[index].index,
                    path: utilityItem.path,
                    id: utilityItem.id,
                    title: utilityItem.title,
                    color: utilityItem.color,
                    faviconLink: utilityItem.faviconLink,
                    browser: utilityItem.browser,
                    imageData: utilityItem.imageData,
                    scriptCode: utilityItem.scriptCode,
                    utilityType: utilityItem.utilityType,
                    objects: utilityItem.objects,
                    showTitleOnIcon: utilityItem.showTitleOnIcon ?? true,
                    category: utilityItem.category
                )
            }
            UserDefaults.standard.store(quickActionItems, for: .quickActionItems)
        } else {
            utilities.insert(utilityItem, at: 0)
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(utilities, for: .utilities)
    }
    
    func openShortcut(name: String) {
        if let url = URL(string: "shortcuts://run-shortcut?name=\(name)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func getShortcutsList() -> [ShortcutObject] {
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/usr/bin/shortcuts"
        process.arguments = ["list"]
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            let list = output?.components(separatedBy: "\n")
                .filter { !$0.isEmpty }
            
            if self.searchText.isEmpty {
                return list?.map {
                    item in .init(
                        type: .shortcut,
                        page: 1,
                        id: shortcuts.first(where: { shortcut in item == shortcut.title })?.id
                        ?? configuredShortcuts.first(where: { shortcut in item == shortcut.title })?.id
                        ?? UUID().uuidString,
                        title: item,
                        color: testColor,
                        imageData: NSImage(named: "shortcuts")?.tiffRepresentation
                    )
                } ?? []
            } else {
                return list?.filter { $0.lowercased().contains(self.searchText.lowercased()) }
                    .map {
                        item in .init(
                            type: .shortcut,
                            page: 1,
                            id: shortcuts.first(where: { shortcut in item == shortcut.title })?.id
                            ?? configuredShortcuts.first(where: { shortcut in item == shortcut.title })?.id
                            ?? UUID().uuidString,
                            title: item,
                            color: testColor,
                            imageData: NSImage(named: "shortcuts")?.tiffRepresentation
                        )
                    } ?? []
            }
        } catch {
            print("Failed to fetch shortcuts: \(error)")
            return []
        }
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { [weak self] _ in
            self?.fetchShortcuts()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func fetchInstalledApps() {
        let appDirectories = [
            "/Applications",
            "/System/Applications/Utilities"
        ]

        var apps: [ShortcutObject] = []
        DispatchQueue.main.async {
            for directory in appDirectories {
                apps.append(contentsOf: self.findApps(in: directory))
            }
            
            self.appsAddedByUser.forEach { userApp in
                if apps.contains(where: { $0.path != userApp.path }) {
                    apps.append(userApp)
                }
            }
            
            if self.searchText.isEmpty {
                self.installedApps = apps.sorted { $0.title.lowercased() < $1.title.lowercased() }
                self.installedAllApps.removeAll()
            } else {
                self.installedAllApps = apps.sorted { $0.title.lowercased() < $1.title.lowercased() }
                self.installedApps = self.installedAllApps
                    .filter { $0.title.lowercased().contains(self.searchText.lowercased()) }
            }
        }
    }
    
    func addInstalledApp(for path: String) {
        guard installedApps.first(where: { $0.path == path }) == nil else {
            if let index = installedApps.firstIndex(where: { $0.path == path }) {
                installedApps[index].imageData = getIcon(fromAppPath: path)
            }
            scrollToApp = path.appNameFromPath() ?? "Unknown"
            return
        }
        let title = path.appNameFromPath() ?? "Unknown"
        let app = ShortcutObject(
            type: .app,
            page: configuredShortcuts.first(where: { shortcut in path == shortcut.path })?.page ?? 1,
            path: path,
            id: appsAddedByUser.first(where: { shortcut in path == shortcut.path })?.id ?? configuredShortcuts.first(where: { shortcut in path == shortcut.path })?.id ?? UUID().uuidString,
            title: title,
            imageData: cachedIcons[path] ?? getIcon(fromAppPath: path)
        )
        appsAddedByUser.insert(app, at: 0)
        fetchInstalledApps()
        scrollToApp = title
        UserDefaults.standard.store(appsAddedByUser, for: .userApps)
        searchText = searchText
    }
    
    func findApps(in directory: String) -> [ShortcutObject] {
        var apps: [ShortcutObject] = []

        if let appURLs = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for appURL in appURLs where appURL.pathExtension == "app" {
                let appName = appURL.deletingPathExtension().lastPathComponent
                let id: String = installedApps.first(where: { shortcut in appURL.path == shortcut.path })?.id
                ?? installedAllApps.first(where: { shortcut in appURL.path == shortcut.path })?.id
                ?? configuredShortcuts.first(where: { shortcut in appURL.path == shortcut.path })?.id
                ?? UUID().uuidString
                apps.append(
                    ShortcutObject(
                        type: .app,
                        page: configuredShortcuts.first(where: { shortcut in appURL.path == shortcut.path })?.page ?? 1,
                        path: appURL.path,
                        id: id,
                        title: appName,
                        imageData: cachedIcons[appURL.path] ?? getIcon(fromAppPath: appURL.path)
                    )
                )
            }
        }

        return apps
    }
    
    var countMB = 0.0
    
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
        cachedIcons[appPath] = pngData
        
//        let sizeInMB = Double(pngData.count) / (1024.0 * 1024.0)
//        countMB += sizeInMB
//        print(String(format: "%.8f MB", countMB))
        
        return pngData
    }
}

extension Array {
    func allIndexes(where predicate: (Element) -> Bool) -> [Int] {
        var indexes: [Int] = []
        for (index, element) in self.enumerated() {
            if predicate(element) {
                indexes.append(index)
            }
        }
        return indexes
    }
}

extension ShortcutObject {
    static func empty(for index: Int, page: Int = 1) -> ShortcutObject {
        .init(type: .app, page: page, index: index, id: "EMPTY \(index)", title: "EMPTY")
    }
}
