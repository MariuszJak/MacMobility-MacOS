//
//  ContentView.swift
//  MagicTrackpad
//
//  Created by CoderBlocks on 05/07/2023.
//

import SwiftUI
import QRCode
import os
import WebKit

enum WorkspaceControl: String, CaseIterable {
    case prev, next
}

struct MacOSMainPopoverView: View {
    @StateObject var connectionManager: ConnectionManager
    @StateObject var viewModel = MacOSMainPopoverViewModel()
    @State private var permissionsWindow: NSWindow?
    @State private var shortcutsWindow: NSWindow?
    @State private var licenseWindow: NSWindow?
    @State private var workspacesWindow: NSWindow?
    @State var isAccessibilityGranted: Bool = false
    private var spacing = 6.0
    
    init(connectionManager: ConnectionManager) {
        self._connectionManager = .init(wrappedValue: connectionManager)
        self.isAccessibilityGranted = AXIsProcessTrusted()
    }
    
    var body: some View {
        VStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: spacing) {
                HStack(alignment: .top, spacing: spacing * 2) {
                    VStack(alignment: .leading, spacing: spacing) {
                        mainView()
//                        debugButtons()
                    }
                    qrCodeViewWithTrialCheck()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: connectionManager.isConnecting ? 270 : 200)
            .if(connectionManager.isConnecting) {
                $0.frame(maxHeight: 130)
            }
            .padding()
        }
    }
    
    @ViewBuilder
    func debugButtons() -> some View {
        // TODO: Remove!
        Button("Clear license") {
            viewModel.appLincenseManager.degrade()
        }
        Button("Reset trial") {
            viewModel.resetTrial()
        }
        // TODO: End
    }
    
    @ViewBuilder
    func mainView() -> some View {
        if viewModel.isPaidLicense {
            permissionView
            Divider()
            shortcutsWindowButtonView
            pairiningView
            if connectionManager.isConnecting {
                Spacer()
            }
            Divider()
            quitView
        } else {
            licenseWindowButtonView
            permissionView
            Divider()
            if viewModel.isTrialExpired {
                Button {
                    let url = NSURL(string: "https://coderblocks.eu/macmobility/") as? URL
                    NSWorkspace.shared.open(url!, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                        if let error { print(error) }
                    }
                } label: {
                    Text("Trial phase ended! Buy license.")
                        .foregroundStyle(Color.red)
                }

            } else {
                HStack(spacing: 2) {
                    shortcutsWindowButtonView
                    Text("(Demo)")
                        .onTapGesture {
                            openShortcutsWindow()
                        }
                }
                pairiningView
                if connectionManager.isConnecting {
                    Spacer()
                }
            }
            Divider()
            quitView
        }
    }
    
    @ViewBuilder
    private func qrCodeViewWithTrialCheck() -> some View {
        if viewModel.isPaidLicense {
            if connectionManager.isConnecting {
                Divider()
            }
            qrCodeView
        } else {
            if !viewModel.isTrialExpired {
                if connectionManager.isConnecting {
                    Divider()
                }
                qrCodeView
            }
        }
    }
    
    private func openShortcutsWindow() {
        if nil == shortcutsWindow {
            shortcutsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1300, height: 850),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            shortcutsWindow?.level = .floating
            shortcutsWindow?.center()
            shortcutsWindow?.setFrameAutosaveName("Shortcuts")
            shortcutsWindow?.isReleasedWhenClosed = false
            shortcutsWindow?.titlebarAppearsTransparent = true
            shortcutsWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: shortcutsWindow) else {
                return
            }
            
            shortcutsWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: ShortcutsView(viewModel: .init(connectionManager: connectionManager)))
            shortcutsWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = shortcutsWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        shortcutsWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openPermissionsWindow() {
        if nil == permissionsWindow {
            permissionsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 300),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            permissionsWindow?.level = .floating
            permissionsWindow?.center()
            permissionsWindow?.setFrameAutosaveName("Permissions")
            permissionsWindow?.isReleasedWhenClosed = false
            permissionsWindow?.titlebarAppearsTransparent = true
            permissionsWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: permissionsWindow) else {
                return
            }
            
            permissionsWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: PermissionView(viewModel: .init(connectionManager: connectionManager)))
            permissionsWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = permissionsWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        permissionsWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openLicenseWindow() {
        if nil == licenseWindow {
            licenseWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 280),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            licenseWindow?.level = .floating
            licenseWindow?.center()
            licenseWindow?.setFrameAutosaveName("License")
            licenseWindow?.isReleasedWhenClosed = false
            licenseWindow?.titlebarAppearsTransparent = true
            licenseWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: licenseWindow) else {
                return
            }
            
            licenseWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: ValidateLicenseView(viewModel: .init()))
            licenseWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = licenseWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        licenseWindow?.makeKeyAndOrderFront(nil)
    }
    
    private var qrCodeView: some View {
        VStack(spacing: .zero) {
            if connectionManager.isConnecting {
                VStack(spacing: spacing) {
                    if let image = generateQRCode() {
                        Text("Scan to connect")
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: 80, height: 80)
                    }
                }
            } else {
                VStack {}
            }
        }
    }
    
    private var permissionView: some View {
        Button("Ask for permission") {
            openPermissionsWindow()
        }
    }
    
    private var shortcutsWindowButtonView: some View {
        Button("Workspace") {
            openShortcutsWindow()
        }
    }
    
    private var licenseWindowButtonView: some View {
        Button("Verify license") {
            openLicenseWindow()
        }
    }
    
    @ViewBuilder
    private var pairiningView: some View {
        switch connectionManager.pairingStatus {
        case .notPaired:
            if let availablePeer = connectionManager.availablePeer {
                VStack(alignment: .leading, spacing: spacing) {
                    Button("Connect to \(availablePeer.displayName)") {
                        connectionManager.invitePeer(with: availablePeer)
                        connectionManager.pairingStatus = .pairining
                    }
                }
            }
        case .paired:
            VStack(alignment: .leading, spacing: spacing) {
                Button("Disconnect from \(connectionManager.connectedPeerName ?? "")") {
                    connectionManager.disconnect()
                    connectionManager.pairingStatus = .notPaired
                }
            }
        case .pairining:
            Text("Pairining...(please wait)")
                .foregroundStyle(.gray)
            Button {
                connectionManager.cancel()
            } label: {
                Text("Cancel pairing")
                    .foregroundStyle(Color.red)
            }
        }
    }
    
    private var quitView: some View {
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
    
    func generateQRCode() -> NSImage? {
        let code = connectionManager.generateUUID()
        let doc = QRCode.Document(utf8String: code, errorCorrection: .high)
        guard let generated = doc.cgImage(CGSize(width: 800, height: 800)) else { return nil }
        return NSImage(cgImage: generated, size: .init(width: 80, height: 80))
    }
}
