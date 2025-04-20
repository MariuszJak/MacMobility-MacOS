//
//  MacMobility_MacOSApp.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 20/01/2024.
//

import SwiftUI

@main
struct MacMobility_MacOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var permissionsWindow: NSWindow?
    private var welcomeWindow: NSWindow?
    private let connectionManager = ConnectionManager()
    var statusItem: NSStatusItem?
    var popOver = NSPopover()
    var menuView: MacOSMainPopoverView?
    var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        register()
        menuView = MacOSMainPopoverView(connectionManager: connectionManager)
        popOver.behavior = .transient
        popOver.animates = true
        popOver.contentViewController = NSViewController()
        popOver.contentViewController?.view = NSHostingView(rootView: menuView)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let lifecycle: Lifecycle = UserDefaults.standard.get(key: .lifecycle) ?? .init(openCount: 0)
        openWelcomeWindow()
        if lifecycle.openCount < 2 {
            openPermissionsWindow()
            let openCount = lifecycle.openCount + 1
            UserDefaults.standard.store(Lifecycle(openCount: openCount), for: .lifecycle)
        }
        
        if let menuButton = statusItem?.button {
            menuButton.image = NSImage(named: "app-icon")
            menuButton.action = #selector(menuAction)
        }
        NSApp.setActivationPolicy(.accessory)
    }
    
    func openWelcomeWindow() {
        if nil == welcomeWindow {
            welcomeWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            welcomeWindow?.center()
            welcomeWindow?.setFrameAutosaveName("Welcome")
            welcomeWindow?.isReleasedWhenClosed = false
            welcomeWindow?.titlebarAppearsTransparent = true
            welcomeWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: welcomeWindow) else {
                return
            }
            
            welcomeWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: WelcomeView(viewModel: .init(closeAction: { setupMode, automatedActions in
                self.welcomeWindow?.close()
            })))
            welcomeWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = welcomeWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        welcomeWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openPermissionsWindow() {
        if nil == permissionsWindow {
            permissionsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 300),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
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
    
    @objc
    func menuAction(sender: AnyObject) {
        if popOver.isShown {
            popOver.performClose(sender)
        } else {
            if let menuButton = statusItem?.button {
                self.popOver.show(relativeTo: menuButton.bounds, of: menuButton, preferredEdge: NSRectEdge.minY)
                popOver.contentViewController?.view.window?.makeKey()
            }
        }
    }
}

extension AppDelegate {
    func register() {
        Resolver.register(Resolver.register(DBSDataProvider() as DBSDataProviderRepresentable))
        Resolver.register(LicenseValidationAPI() as LicenseValidationAPIProtocol)
        Resolver.register(LicenseValidationUseCase() as LicenseValidationUseCaseProtocol)
        Resolver.register(AppUpdateAPI() as AppUpdateAPIProtocol)
        Resolver.register(AppUpdateUseCase() as AppUpdateUseCaseProtocol)
        Resolver.register(AppLicenseManager(), .locked)
        Resolver.register(UpdatesManager(), .locked)
    }
}
