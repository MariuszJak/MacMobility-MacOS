//
//  ShortcutsViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 16/03/2025.
//

import SwiftUI
import Combine

public struct ShortcutObject: Identifiable, Codable {
    public let index: Int?
    public let id: String
    public let title: String
    public var color: String?
    
    public init(index: Int? = nil, id: String, title: String, color: String? = nil) {
        self.index = index
        self.id = id
        self.title = title
        self.color = color
    }
}

public class ShortcutsViewModel: ObservableObject {
    let connectionManager: ConnectionManager
    @Published var configuredShortcuts: [ShortcutObject] = []
    @Published var shortcuts: [ShortcutObject] = []
    @Published var searchText: String = ""
    @Published var cancellables = Set<AnyCancellable>()
    
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        self.configuredShortcuts = UserDefaults.standard.getShortcutsItems() ?? []
        fetchShortcuts()
        registerListener()
    }
    
    func objectAt(index: Int) -> ShortcutObject? {
        configuredShortcuts.first(where: { $0.index == index })
    }
    
    func object(for id: String) -> ShortcutObject? {
        shortcuts.first { $0.id == id }
    }
    
    func removeShortcut(id: String) {
        configuredShortcuts.removeAll { $0.id == id }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.storeShortcutsItems(configuredShortcuts)
    }
    
    func addConfiguredShortcut(object: ShortcutObject) {
        if let index = configuredShortcuts.firstIndex(where: { $0.index == object.index }) {
            configuredShortcuts[index] = object
            configuredShortcuts.enumerated().forEach { (index, shortcut) in
                if (object.index != shortcut.index && shortcut.id == object.id) {
                    configuredShortcuts.remove(at: index)
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
            }
            .store(in: &cancellables)
    }
    
    func fetchShortcuts() {
        shortcuts = getShortcutsList()
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
                        id: configuredShortcuts.first(where: { shortcut in item == shortcut.title })?.id ?? UUID().uuidString,
                        title: item,
                        color: configuredShortcuts.first(where: { shortcut in item == shortcut.title })?.color ?? Color.randomDarkPastel.toHex()
                    )
                } ?? []
            } else {
                return list?.filter { $0.lowercased().contains(self.searchText.lowercased()) }
                    .map {
                        item in .init(
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
}
