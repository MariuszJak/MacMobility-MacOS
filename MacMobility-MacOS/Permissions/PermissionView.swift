//
//  PermissionView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 28/03/2025.
//

import SwiftUI
import Network
import AppKit

class PermissionViewModel: ObservableObject {
    private let connectionManager: ConnectionManager
    private var browser: NWBrowser?
    
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        requestLocalNetworkAccess()
    }
    
    func askForPermission() {
        guard !AXIsProcessTrusted() else { return }
        
        let alert = NSAlert()
        alert.messageText = "Accessibility Access Required"
        alert.informativeText = "Your app needs accessibility access to perform certain actions. Please enable accessibility access in System Preferences."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
    
    func requestLocalNetworkAccess() {
        connectionManager.startBrowsing()
    }
}

struct PermissionView: View {
    @ObservedObject private var viewModel: PermissionViewModel
    
    init(viewModel: PermissionViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12.0) {
                Text("Accessibility Permission")
                    .font(.title2)
                    .bold()
                Button("Ask for permission") {
                    viewModel.askForPermission()
                }
                .disabled(AXIsProcessTrusted())
                Text("We need access to your system to allow accessibility features to work correctly. Please allow this permission in your system preferences.")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color.gray)
            }
            .padding()
            Spacer()
        }
    }
}
