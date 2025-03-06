//
//  CreateWorkspaceWithMultipleScreensViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 06/03/2025.
//

import Foundation
import SwiftUI
import Combine

class CreateWorkspaceWithMultipleScreensViewModel: ObservableObject {
    @Published var screens: [ScreenItem] = []
    @Published var title: String
    @Published var searchText: String = ""
    @Published var cancellables = Set<AnyCancellable>()
    @Published var installedApps: [AppInfo] = []
    var id: String
    
    public init(workspace: WorkspaceItem? = nil) {
        self.screens = workspace?.screens ?? []
        self.title = workspace?.title ?? ""
        self.id = workspace?.id ?? UUID().uuidString
        registerListener()
    }
    
    func addNewScreen() {
        screens.append(.init(id: UUID().uuidString))
    }
    
    func removeScreen(_ id: String) -> Void {
        screens = screens.filter { $0.id != id }
    }
    
    func registerListener() {
        $searchText
            .sink { [weak self] _ in
                self?.fetchInstalledApps()
            }
            .store(in: &cancellables)
    }
    
    func removeItem(with path: String) {
        screens = screens.filter { $0.id != id }
    }
    
    func save() -> WorkspaceItem? {
        guard !title.isEmpty && !screens.isEmpty else {
            return nil
        }
        return .init(id: id, title: title, screens: screens)
    }
    
    func fetchInstalledApps() {
        let appDirectories = [
            "/Applications",
            "/System/Applications/Utilities"
        ]

        var apps: [AppInfo] = []

        for directory in appDirectories {
            apps.append(contentsOf: findApps(in: directory))
        }

        DispatchQueue.main.async {
            if self.searchText.isEmpty {
                self.installedApps = apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
            } else {
                self.installedApps = apps.sorted { $0.name.lowercased() < $1.name.lowercased() }.filter { $0.name.contains(self.searchText) }
            }
        }
    }
    
    func findApps(in directory: String) -> [AppInfo] {
        var apps: [AppInfo] = []

        if let appURLs = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for appURL in appURLs where appURL.pathExtension == "app" {
                let appName = appURL.deletingPathExtension().lastPathComponent
                apps.append(AppInfo(id: UUID().uuidString, name: appName, path: appURL.path))
            }
        }

        return apps
    }
}
