//
//  ContentView.swift
//  MacMobility
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
    @State private var updatesWindow: NSWindow?
    @State private var aboutWindow: NSWindow?
    @State var isAccessibilityGranted: Bool = false
    private var spacing = 6.0
    private let shorctuctsAction: () -> Void
    
    init(connectionManager: ConnectionManager, shorctuctsAction: @escaping () -> Void) {
        self._connectionManager = .init(wrappedValue: connectionManager)
        self.isAccessibilityGranted = AXIsProcessTrusted()
        self.shorctuctsAction = shorctuctsAction
    }
    
    var body: some View {
        VStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: spacing) {
                HStack(alignment: .top, spacing: spacing * 2) {
                    VStack(alignment: .leading, spacing: spacing) {
                        mainView()
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 200)
            .padding()
        }
        .onAppear {
            Task {
                await viewModel.checkVersion {
                    viewModel.appIsUpToDate = nil
                }
            }
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
        aboutButtonView
        Divider()
        if viewModel.needsUpdate {
            updateAvailableButtonView
        } else {
            checkForUpdateButtonView
        }
        if viewModel.isPaidLicense {
            Divider()
            shortcutsWindowButtonView
            pairiningView
            Divider()
            settingsView
            Divider()
            quitView
        } else {
            licenseWindowButtonView
            Divider()
            if viewModel.isTrialExpired {
                Button {
                    let url = NSURL(string: "https://coderblocks.eu/mobility") as? URL
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
                            shorctuctsAction()
                        }
                }
                pairiningView
            }
            Divider()
            settingsView
            Divider()
            quitView
        }
    }
    
    private func openUpdatesWindow() {
        guard let updateData = viewModel.updateData else {
            return
        }
        if nil == updatesWindow {
            updatesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            updatesWindow?.center()
            updatesWindow?.setFrameAutosaveName("Updates")
            updatesWindow?.isReleasedWhenClosed = false
            updatesWindow?.titlebarAppearsTransparent = true
            updatesWindow?.appearance = NSAppearance(named: .darkAqua)
            updatesWindow?.styleMask.insert(.fullSizeContentView)
            updatesWindow?.title = "Updates"
            updatesWindow?.titleVisibility = .hidden
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: updatesWindow) else {
                return
            }
            
            updatesWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: UpdateScreenView(viewModel: .init(updateData: updateData)))
            updatesWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = updatesWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        updatesWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openPermissionsWindow() {
        if nil == permissionsWindow {
            permissionsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            permissionsWindow?.center()
            permissionsWindow?.setFrameAutosaveName("Permissions")
            permissionsWindow?.isReleasedWhenClosed = false
            permissionsWindow?.titlebarAppearsTransparent = true
            permissionsWindow?.appearance = NSAppearance(named: .darkAqua)
            permissionsWindow?.styleMask.insert(.fullSizeContentView)
            permissionsWindow?.title = "Permissions"
            permissionsWindow?.titleVisibility = .hidden
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: permissionsWindow) else {
                return
            }
            
            permissionsWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: SettingsView(connectionManager: connectionManager))
            permissionsWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = permissionsWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        permissionsWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openLicenseWindow() {
        if nil == licenseWindow {
            licenseWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 380),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            licenseWindow?.center()
            licenseWindow?.setFrameAutosaveName("License")
            licenseWindow?.isReleasedWhenClosed = false
            licenseWindow?.titlebarAppearsTransparent = true
            licenseWindow?.appearance = NSAppearance(named: .darkAqua)
            licenseWindow?.styleMask.insert(.fullSizeContentView)
            licenseWindow?.title = "License"
            licenseWindow?.titleVisibility = .hidden
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
    
    private func openAboutWindow() {
        if nil == aboutWindow {
            aboutWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            aboutWindow?.center()
            aboutWindow?.setFrameAutosaveName("About")
            aboutWindow?.isReleasedWhenClosed = false
            aboutWindow?.titlebarAppearsTransparent = true
            aboutWindow?.appearance = NSAppearance(named: .darkAqua)
            aboutWindow?.styleMask.insert(.fullSizeContentView)
            aboutWindow?.title = "About"
            aboutWindow?.titleVisibility = .hidden
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: aboutWindow) else {
                return
            }
            
            aboutWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: AboutView())
            aboutWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = aboutWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        aboutWindow?.makeKeyAndOrderFront(nil)
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
    
    private var settingsView: some View {
        Button {
            openPermissionsWindow()
        } label: {
            HStack {
                Image(systemName: "gearshape")
                Text("Settings")
            }
        }
    }
    
    private var aboutButtonView: some View {
        Button {
            openAboutWindow()
        } label: {
            HStack {
                Image(systemName: "info.circle")
                Text("About")
            }
        }
    }
    
    @ViewBuilder
    private var updateAvailableButtonView: some View {
        Button {
            openUpdatesWindow()
        } label: {
            HStack {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .foregroundStyle(Color.green)
                Text("Update Available!")
            }
        }
    }
    
    @ViewBuilder
    private var checkForUpdateButtonView: some View {
        if viewModel.isCheckingForUpdate {
            Text("Checking for update...")
                .foregroundStyle(.gray)
        } else {
            if let appIsUpToDate = viewModel.appIsUpToDate, appIsUpToDate {
                Text("You have current version")
                    .foregroundStyle(Color.green)
            } else {
                Button {
                    Task {
                        await viewModel.checkVersion()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        Text("Check for update")
                    }
                }
            }
        }
    }
    
    private var shortcutsWindowButtonView: some View {
        Button {
            shorctuctsAction()
        } label: {
            HStack {
                Image(systemName: "macwindow.on.rectangle")
                Text("Workspace")
            }
        }
    }
    
    private var licenseWindowButtonView: some View {
        Button {
            openLicenseWindow()
        } label: {
            HStack {
                Image(systemName: "checkmark.shield")
                Text("Verify license")
            }
        }
    }
    
    @ViewBuilder
    private var pairiningView: some View {
        switch connectionManager.pairingStatus {
        case .notPaired:
            if let availablePeerWithName = connectionManager.availablePeerWithName,
               let availablePeer = availablePeerWithName.0 {
                VStack(alignment: .leading, spacing: spacing) {
                    Button {
                        connectionManager.invitePeer(with: availablePeer)
                        connectionManager.pairingStatus = .pairining
                    } label: {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundStyle(Color.accentColor)
                            Text("Connect to \(availablePeerWithName.1)")
                                .font(.system(size: 14.0, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                        }
                    }

                }
            }
        case .paired:
            VStack(alignment: .leading, spacing: spacing) {
                Button {
                    connectionManager.disconnect()
                    connectionManager.pairingStatus = .notPaired
                } label: {
                    HStack {
                        Image(systemName: "iphone.slash.circle")
                            .foregroundStyle(Color.orange)
                        Text("Disconnect from \(connectionManager.connectedPeerName ?? "")")
                            .foregroundStyle(Color.orange)
                    }
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
        let message = "mobilitycontrol://\(code)"
        let doc = QRCode.Document(utf8String: message, errorCorrection: .high)
        guard let generated = doc.cgImage(CGSize(width: 800, height: 800)) else { return nil }
        return NSImage(cgImage: generated, size: .init(width: 80, height: 80))
    }
}
