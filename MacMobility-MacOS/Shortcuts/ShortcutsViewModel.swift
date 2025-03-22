//
//  ShortcutsViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 16/03/2025.
//

import SwiftUI
import Combine

public enum ShortcutType: String, Codable {
    case shortcut
    case app
    case webpage
    case utility
}

public struct ShortcutObject: Identifiable, Codable, Equatable {
    public let index: Int?
    public var page: Int
    public let id: String
    public let title: String
    public var path: String?
    public var color: String?
    public var faviconLink: String?
    public let type: ShortcutType
    public let imageData: Data?
    public var browser: Browsers?
    public var scriptCode: String?
    public var utilityType: UtilityObject.UtilityType?
    public var objects: [ShortcutObject]?
    
    public init(type: ShortcutType, page: Int, index: Int? = nil, path: String? = nil, id: String, title: String, color: String? = nil, faviconLink: String? = nil, browser: Browsers? = nil, imageData: Data? = nil, scriptCode: String? = nil, utilityType: UtilityObject.UtilityType? = nil, objects: [ShortcutObject]? = nil) {
        self.page = page
        self.type = type
        self.index = index
        self.path = path
        self.id = id
        self.title = title
        self.color = color
        self.scriptCode = scriptCode
        self.utilityType = utilityType
        switch type {
        case .shortcut:
            self.imageData = imageData
        case .app:
            self.imageData = try? NSWorkspace.shared.icon(forFile: path ?? "").imageData(for: .png(scale: 0.2, excludeGPSData: false))
        case .webpage:
            self.imageData = imageData
        case .utility:
            self.imageData = imageData
        }
        self.faviconLink = faviconLink
        self.browser = browser
        self.objects = objects
    }
}

public class ShortcutsViewModel: ObservableObject, WebpagesWindowDelegate, UtilitiesWindowDelegate {
    let connectionManager: ConnectionManager
    @Published var configuredShortcuts: [ShortcutObject] = []
    @Published var shortcuts: [ShortcutObject] = []
    @Published var installedApps: [ShortcutObject] = []
    @Published var webpages: [ShortcutObject] = []
    @Published var utilities: [ShortcutObject] = []
    @Published var searchText: String = ""
    @Published var cancellables = Set<AnyCancellable>()
    @Published var pages = 1
    var close: () -> Void = {}
    private var timer: Timer?
    public var testColor = "#6DDADE"
    private var allWebpages: [ShortcutObject] = []
    
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        self.configuredShortcuts = UserDefaults.standard.getShortcutsItems() ?? []
        self.webpages = UserDefaults.standard.getWebItems() ?? []
        self.utilities = UserDefaults.standard.getUtilitiesItems() ?? []
        self.pages = UserDefaults.standard.getPagesCount() ?? 1
        fetchShortcuts()
        fetchInstalledApps()
        registerListener()
        startMonitoring()
    }
    
    func registerListener() {
        $searchText
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchShortcuts()
                self?.fetchInstalledApps()
                self?.searchWebpages()
                self?.searchUtilities()
            }
            .store(in: &cancellables)
    }
    
    func objectAt(index: Int, page: Int) -> ShortcutObject? {
        configuredShortcuts.filter { $0.page == page }.first(where: { $0.index == index })
    }
    
    func object(for id: String) -> ShortcutObject? {
        shortcuts.first { $0.id == id } ?? installedApps.first { $0.id == id } ?? webpages.first { $0.id == id } ?? utilities.first { $0.id == id }
    }
    
    func allObjects() -> [ShortcutObject] {
        shortcuts + installedApps + webpages + utilities
    }
    
    func removeShortcut(id: String) {
        configuredShortcuts.removeAll { $0.id == id }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.storeShortcutsItems(configuredShortcuts)
    }
    
    func addPage() {
        pages += 1
        UserDefaults.standard.storePages(pages)
    }
    
    func removePage(with number: Int) {
        configuredShortcuts.removeAll { $0.page == number }
        configuredShortcuts.enumerated().forEach { (index, object) in
            if configuredShortcuts[index].page > number {
                configuredShortcuts[index].page -= 1
            }
        }
        if pages > 1 {
            pages -= 1
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.storeShortcutsItems(configuredShortcuts)
        UserDefaults.standard.storePages(pages)
    }
    
    func removeWebItem(id: String) {
        webpages.removeAll { $0.id == id }
        configuredShortcuts.removeAll { $0.id == id }
        UserDefaults.standard.storeWebItems(webpages)
        connectionManager.shortcuts = configuredShortcuts
    }
    
    func removeUtilityItem(id: String) {
        utilities.removeAll { $0.id == id }
        configuredShortcuts.removeAll { $0.id == id }
        UserDefaults.standard.storeUtilitiesItems(utilities)
        connectionManager.shortcuts = configuredShortcuts
    }
    
    func addConfiguredShortcut(object: ShortcutObject) {
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
                        utilityType: oldObject.utilityType,
                        objects: oldObject.objects
                    )
                }
            }
        } else {
            configuredShortcuts = configuredShortcuts.filter { $0.id != object.id }
            configuredShortcuts.append(object)
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.storeShortcutsItems(configuredShortcuts)
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
                utilities[index].path = ""
            } else {
                utilities[index].path = utility.title.lowercased().contains(self.searchText.lowercased()) ? "" : "Hidden"
            }
        }
    }
    
    func fetchShortcuts() {
        shortcuts = getShortcutsList()
    }
    
    func saveWebpage(with webpageItem: ShortcutObject) {
        if let index = webpages.firstIndex(where: { $0.id == webpageItem.id }) {
            webpages[index] = webpageItem
            if let configuredIndex = configuredShortcuts.firstIndex(where: { $0.id == webpageItem.id }) {
                configuredShortcuts[configuredIndex] = .init(
                    type: webpageItem.type,
                    page: configuredShortcuts[configuredIndex].page,
                    index: configuredShortcuts[configuredIndex].index,
                    path: webpageItem.path,
                    id: webpageItem.id,
                    title: webpageItem.title,
                    color: webpageItem.color,
                    faviconLink: webpageItem.faviconLink,
                    browser: webpageItem.browser,
                    imageData: webpageItem.imageData,
                    objects: webpageItem.objects
                )
                UserDefaults.standard.storeShortcutsItems(configuredShortcuts)
            }
        } else {
            webpages.insert(webpageItem, at: 0)
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.storeWebItems(webpages)
    }
    
    func saveUtility(with utilityItem: ShortcutObject) {
        if let index = utilities.firstIndex(where: { $0.id == utilityItem.id }) {
            utilities[index] = utilityItem
            if let configuredIndex = configuredShortcuts.firstIndex(where: { $0.id == utilityItem.id }) {
                configuredShortcuts[configuredIndex] = .init(
                    type: utilityItem.type,
                    page: configuredShortcuts[configuredIndex].page,
                    index: configuredShortcuts[configuredIndex].index,
                    path: utilityItem.path,
                    id: utilityItem.id,
                    title: utilityItem.title,
                    color: utilityItem.color,
                    faviconLink: utilityItem.faviconLink,
                    browser: utilityItem.browser,
                    imageData: utilityItem.imageData,
                    scriptCode: utilityItem.scriptCode,
                    utilityType: utilityItem.utilityType,
                    objects: utilityItem.objects
                )
                UserDefaults.standard.storeShortcutsItems(configuredShortcuts)
            }
        } else {
            utilities.insert(utilityItem, at: 0)
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.storeUtilitiesItems(utilities)
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
                        color: testColor
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
                            color: testColor
                        )
                    } ?? []
            }
        } catch {
            print("Failed to fetch shortcuts: \(error)")
            return []
        }
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
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

        for directory in appDirectories {
            apps.append(contentsOf: findApps(in: directory))
        }

        DispatchQueue.main.async {
            if self.searchText.isEmpty {
                self.installedApps = apps.sorted { $0.title.lowercased() < $1.title.lowercased() }
            } else {
                self.installedApps = apps.sorted { $0.title.lowercased() < $1.title.lowercased() }
                    .filter { $0.title.lowercased().contains(self.searchText.lowercased()) }
            }
        }
    }
    
    func findApps(in directory: String) -> [ShortcutObject] {
        var apps: [ShortcutObject] = []

        if let appURLs = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for appURL in appURLs where appURL.pathExtension == "app" {
                let appName = appURL.deletingPathExtension().lastPathComponent
                apps.append(
                    ShortcutObject(
                        type: .app,
                        page: configuredShortcuts.first(where: { shortcut in appURL.path == shortcut.path })?.page ?? 1,
                        path: appURL.path,
                        id: installedApps.first(where: { shortcut in appURL.path == shortcut.path })?.id ?? configuredShortcuts.first(where: { shortcut in appURL.path == shortcut.path })?.id ?? UUID().uuidString,
                        title: appName
                    )
                )
            }
        }

        return apps
    }
}
