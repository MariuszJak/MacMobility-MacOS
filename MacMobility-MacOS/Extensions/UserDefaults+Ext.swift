//
//  UserDefaults+Ext.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 14/03/2024.
//

import Foundation

public struct Pages: Codable {
    let pages: Int
}

public struct Lifecycle: Codable {
    let openCount: Int
}

extension UserDefaults {
    func store<T: Codable>(_ entity: T, for key: Const) {
        guard let data = try? JSONEncoder().encode(entity) else { return }
        let url = Self.fileURL(for: key)
        try? data.write(to: url, options: [.atomic])
    }

    func get<T: Codable>(key: Const) -> T? {
        let url = Self.fileURL(for: key)

        // If file exists, use it
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(T.self, from: data) {
            return decoded
        }

        // Otherwise, try loading from old UserDefaults and migrate it
        guard let itemsData = object(forKey: key) as? Data,
              let object = try? JSONDecoder().decode(T.self, from: itemsData) else {
            return nil
        }

        // Store the legacy object in file and remove from UserDefaults
        store(object, for: key)
        set(nil, forKey: key) // Cleanup
        return object
    }

    func clear(key: Const) {
        let url = Self.fileURL(for: key)
        try? FileManager.default.removeItem(at: url)
        set(nil, forKey: key) // Optional: also clean legacy UserDefaults
    }

    func clearAll() {
        for key in Const.allCases {
            clear(key: key)
        }
    }

    private static func fileURL(for key: Const) -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = directory.appendingPathComponent("MacMobilityStorage", isDirectory: true)

        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        return folder.appendingPathComponent("\(key.rawValue).json")
    }
}

extension UserDefaults {
    func storeUserDefaults<T: Codable>(_ entity: T, for key: Const) {
        guard let jsonData = try? JSONEncoder().encode(entity) else {
            return
        }

        set(jsonData, forKey: key)
    }
    
    func getUserDefaults<T: Codable>(key: Const) -> T? {
        guard let itemsData = object(forKey: key) as? Data,
              let object = try? JSONDecoder().decode(T.self, from: itemsData) else {
            return nil
        }
        return object
    }
    
    func clearUserDefaults(key: Const) {
        set(nil, forKey: key)
    }
    
    func clearAllUserDefaults() {
        for key in Const.allCases {
            set(nil, forKey: key)
        }
    }
}

extension UserDefaults {
    enum Const: String, CaseIterable {
        case webItems
        case workspaceItems
        case shortcuts
        case pages
        case subitemPages
        case subitemCurrentPage
        case utilities
        case license
        case licenseKey
        case firstActivationDate
        case userApps
        case lifecycle
        case browser
        case assignedAppsToPages
        case quickActionItems
        case quickActionTutorialSeen
    }

    func set(_ value: Any?, forKey defaultName: Const) {
        set(value, forKey: defaultName.rawValue)
    }

    func object(forKey defaultName: Const) -> Any? {
        object(forKey: defaultName.rawValue)
    }
}

import SwiftUI
import AppKit
import Combine

class FocusedAppObserver: ObservableObject {
    @Published var focusedAppName: String? = nil
    private var cancellable: AnyCancellable?

    init() {
        // Observe changes in the frontmost app
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        // Initial state
        updateFrontmostApp()
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func appDidActivate(notification: Notification) {
        updateFrontmostApp()
    }

    private func updateFrontmostApp() {
        if let app = NSWorkspace.shared.frontmostApplication {
            self.focusedAppName = app.localizedName
        } else {
            self.focusedAppName = nil // Possibly no app focused
        }
    }
}
