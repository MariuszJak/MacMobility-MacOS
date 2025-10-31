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
    @Published var showAlert: Bool = false
    private let connectionManager: ConnectionManager
    private var browser: NWBrowser?
    
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        requestLocalNetworkAccess()
    }
    
    func askForPermission() {
        guard !AXIsProcessTrusted() else { return }
        showAlert = true
    }
    
    func openAccessibilitySettings() {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let major = osVersion.majorVersion
        let minor = osVersion.minorVersion
        
        // ✅ macOS 15 (Tahoe) and later – new URL scheme
        if major >= 15 {
            if let url = URL(string: "x-apple.systempreferences:com.apple.Settings.PrivacySecurity.extension?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
                return
            }
        }
        
        // ✅ macOS 13–14 (Ventura, Sonoma)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
            return
        }
        
        // Fallback — open the Security & Privacy pane generally
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func requestLocalNetworkAccess() {
        connectionManager.startBrowsing()
    }
}

struct PermissionView: View {
    @ObservedObject private var viewModel: PermissionViewModel
    private let alignment: HorizontalAlignment
    
    init(viewModel: PermissionViewModel, alignment: HorizontalAlignment = .leading) {
        self.viewModel = viewModel
        self.alignment = alignment
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: alignment, spacing: 12.0) {
                Text("Accessibility Permission")
                    .font(.title2)
                    .bold()
                Button("Ask for permission") {
                    viewModel.askForPermission()
                }
                .disabled(AXIsProcessTrusted())
                Text("We need access to your system to allow accessibility features to work correctly. Please allow this permission in your system preferences.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color.gray)
            }
            .padding()
            Spacer()
        }
        .alert("Accessibility Access Required", isPresented: $viewModel.showAlert) {
            Button("Open Settings", role: .none) {
                viewModel.showAlert = false
                viewModel.openAccessibilitySettings()
            }
            Button("Cancel", role: .cancel) {
                viewModel.showAlert = false
                
            }
        } message: {
            Text("""
        Your app needs accessibility access to perform certain actions.
        Please enable it in System Settings → Privacy & Security → Accessibility.
        """)
        }
    }
}
