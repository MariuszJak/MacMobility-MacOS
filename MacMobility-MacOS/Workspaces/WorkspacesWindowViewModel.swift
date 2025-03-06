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
    @Published var workspaces2: [WorkspaceItem] = []
    let connectionManager: ConnectionManager
    var cancellables = Set<AnyCancellable>()
    var close: () -> Void = {}
    
    init(selectedId: String? = nil, connectionManager: ConnectionManager, close: @escaping () -> Void = {}) {
        self.selectedId = selectedId
        self.connectionManager = connectionManager
        self.workspaces2 = UserDefaults.standard.getWorkspaceItems2() ?? []
        self.close = close
    }
    
    func refreshFromStorage() {
        workspaces2 = UserDefaults.standard.getWorkspaceItems2() ?? []
    }
    
    func getAutomations() -> [WorkspaceItem] {
        workspaces2
    }
    
    func saveWorkspace(with item: WorkspaceItem) {
        if let index = workspaces2.firstIndex(where: { $0.id == item.id }) {
            workspaces2[index] = item
            UserDefaults.standard.storeWorkspaceItems2(workspaces2)
            connectionManager.workspaces = workspaces2
            return
        }
        workspaces2.append(item)
        connectionManager.workspaces = workspaces2
        UserDefaults.standard.storeWorkspaceItems2(workspaces2)
    }
    
    func removeWorkspace2(with item: WorkspaceItem) {
        workspaces2 = workspaces2.filter { $0.id != item.id }
        connectionManager.workspaces = workspaces2
        UserDefaults.standard.storeWorkspaceItems2(workspaces2)
    }
    
    func saveWebpages() {
        UserDefaults.standard.storeWorkspaceItems2(workspaces2)
    }
}
