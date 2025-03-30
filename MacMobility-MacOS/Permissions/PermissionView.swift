//
//  PermissionView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 28/03/2025.
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NSApplication.shared.terminate(nil)
            }
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
            VStack {
                Spacer()
                Image(.logo)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .cornerRadius(20)
                Spacer()
            }
            .padding()
            VStack(alignment: .leading) {
                Spacer()
                Text("Accessibility Permission")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.bottom, 6.0)
                Text("We need access to your system to allow accessibility features to work correctly. Please allow this permission in your system preferences.")
                    .foregroundStyle(Color.gray)
                    .padding(.bottom, 6.0)
                Text("This action will close this app, please restart it after allowing the permission.")
                    .foregroundStyle(Color.white)
                    .padding(.bottom, 18.0)
                Button("Ask for permission") {
                    viewModel.askForPermission()
                }
                .disabled(AXIsProcessTrusted())
                .padding(.bottom, 42)
                Spacer()
            }
            .padding()
        }
        .padding(.horizontal, 21.0)
    }
}
