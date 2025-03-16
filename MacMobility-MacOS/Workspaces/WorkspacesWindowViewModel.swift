//
//  WorkspacesWindowViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 27/02/2025.
//

import SwiftUI
import Combine

class WorkspacesWindowViewModel: ObservableObject, WorkspaceWindowDelegate {
    @Published var selectedId: String?
    @Published var workspaces: [WorkspaceItem] = []
    let connectionManager: ConnectionManager
    var cancellables = Set<AnyCancellable>()
    var close: () -> Void = {}
    
    init(selectedId: String? = nil, connectionManager: ConnectionManager, close: @escaping () -> Void = {}) {
        self.selectedId = selectedId
        self.connectionManager = connectionManager
        self.workspaces = UserDefaults.standard.getWorkspaceItems() ?? []
        self.close = close
    }
    
    func refreshFromStorage() {
        workspaces = UserDefaults.standard.getWorkspaceItems() ?? []
    }
    
    func getAutomations() -> [WorkspaceItem] {
        workspaces
    }
    
    func saveWorkspace(with item: WorkspaceItem) {
        if let index = workspaces.firstIndex(where: { $0.id == item.id }) {
            workspaces[index] = item
            UserDefaults.standard.storeWorkspaceItems(workspaces)
            connectionManager.workspaces = workspaces
            return
        }
        workspaces.append(item)
        connectionManager.workspaces = workspaces
        UserDefaults.standard.storeWorkspaceItems(workspaces)
    }
    
    func removeWorkspace2(with item: WorkspaceItem) {
        workspaces = workspaces.filter { $0.id != item.id }
        connectionManager.workspaces = workspaces
        UserDefaults.standard.storeWorkspaceItems(workspaces)
    }
    
    func saveWebpages() {
        UserDefaults.standard.storeWorkspaceItems(workspaces)
    }
}
