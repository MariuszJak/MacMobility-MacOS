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
}

public struct ShortcutObject: Identifiable, Codable {
    public let index: Int?
    public let id: String
    public let title: String
    public let path: String?
    public var color: String?
    public var faviconLink: String?
    public let type: ShortcutType
    public let imageData: Data?
    public var browser: Browsers?
    
    public init(type: ShortcutType, index: Int? = nil, path: String? = nil, id: String, title: String, color: String? = nil, faviconLink: String? = nil, browser: Browsers? = nil, imageData: Data? = nil) {
        self.type = type
        self.index = index
        self.path = path
        self.id = id
        self.title = title
        self.color = color
        switch type {
        case .shortcut:
            self.imageData = imageData
        case .app:
            self.imageData = try? NSWorkspace.shared.icon(forFile: path ?? "").imageData(for: .png(scale: 0.2, excludeGPSData: false))
        case .webpage:
            self.imageData = imageData
        }
        self.faviconLink = faviconLink
        self.browser = browser
    }
}

public class ShortcutsViewModel: ObservableObject, WebpagesWindowDelegate {
    let connectionManager: ConnectionManager
    @Published var configuredShortcuts: [ShortcutObject] = []
    @Published var shortcuts: [ShortcutObject] = []
    @Published var installedApps: [ShortcutObject] = []
    @Published var webpages: [ShortcutObject] = []
    @Published var searchText: String = ""
    @Published var cancellables = Set<AnyCancellable>()
    var close: () -> Void = {}
    
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        self.configuredShortcuts = UserDefaults.standard.getShortcutsItems() ?? []
        self.webpages = UserDefaults.standard.getWebItems() ?? []
        fetchShortcuts()
        fetchInstalledApps()
        registerListener()
    }
    
    func objectAt(index: Int) -> ShortcutObject? {
        configuredShortcuts.first(where: { $0.index == index })
    }
    
    func object(for id: String) -> ShortcutObject? {
        shortcuts.first { $0.id == id } ?? installedApps.first { $0.id == id } ?? webpages.first { $0.id == id }
    }
    
    func removeShortcut(id: String) {
        configuredShortcuts.removeAll { $0.id == id }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.storeShortcutsItems(configuredShortcuts)
    }
    
    func removeWebItem(id: String) {
        webpages.removeAll { $0.id == id }
        configuredShortcuts.removeAll { $0.id == id }
        UserDefaults.standard.storeWebItems(webpages)
        connectionManager.shortcuts = configuredShortcuts
    }
    
    func addConfiguredShortcut(object: ShortcutObject) {
        if let index = configuredShortcuts.firstIndex(where: { $0.index == object.index }) {
            let oldObject = configuredShortcuts[index]
            configuredShortcuts[index] = object
            configuredShortcuts.enumerated().forEach { (index, shortcut) in
                if (object.index != shortcut.index && shortcut.id == object.id) {
                    configuredShortcuts[index] = .init(
                        type: oldObject.type,
                        index: configuredShortcuts[index].index,
                        path: oldObject.path,
                        id: oldObject.id,
                        title: oldObject.title,
                        color: oldObject.color,
                        faviconLink: oldObject.faviconLink,
                        browser: oldObject.browser,
                        imageData: oldObject.imageData
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
    
    func registerListener() {
        $searchText
            .sink { [weak self] _ in
                self?.fetchShortcuts()
                self?.fetchInstalledApps()
            }
            .store(in: &cancellables)
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
                    index: configuredShortcuts[configuredIndex].index,
                    path: webpageItem.path,
                    id: webpageItem.id,
                    title: webpageItem.title,
                    color: webpageItem.color,
                    faviconLink: webpageItem.faviconLink,
                    browser: webpageItem.browser,
                    imageData: webpageItem.imageData
                )
                UserDefaults.standard.storeShortcutsItems(configuredShortcuts)
            }
        } else {
            webpages.insert(webpageItem, at: 0)
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.storeWebItems(webpages)
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
                        id: configuredShortcuts.first(where: { shortcut in item == shortcut.title })?.id ?? UUID().uuidString,
                        title: item,
                        color: configuredShortcuts.first(where: { shortcut in item == shortcut.title })?.color ?? Color.randomDarkPastel.toHex()
                    )
                } ?? []
            } else {
                return list?.filter { $0.lowercased().contains(self.searchText.lowercased()) }
                    .map {
                        item in .init(
                            type: .shortcut,
                            id: configuredShortcuts.first(where: { shortcut in item == shortcut.title })?.id ?? UUID().uuidString,
                            title: item,
                            color: configuredShortcuts.first(where: { shortcut in item == shortcut.title })?.color ?? Color.randomDarkPastel.toHex()
                        )
                    } ?? []
            }
        } catch {
            print("Failed to fetch shortcuts: \(error)")
            return []
        }
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
                        path: appURL.path,
                        id: configuredShortcuts.first(where: { shortcut in appURL.path == shortcut.path })?.id ?? UUID().uuidString,
                        title: appName,
                        color: configuredShortcuts.first(where: { shortcut in appURL.path == shortcut.path })?.color ?? Color.randomDarkPastel.toHex()
                    )
                )
            }
        }

        return apps
    }
}
