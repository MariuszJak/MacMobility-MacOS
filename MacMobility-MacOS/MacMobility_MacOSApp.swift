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
    var statusItem: NSStatusItem?
    var popOver = NSPopover()
    var menuView: MacOSMainPopoverView?
    var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        register()
        menuView = MacOSMainPopoverView()
        popOver.behavior = .transient
        popOver.animates = true
        popOver.contentViewController = NSViewController()
        popOver.contentViewController?.view = NSHostingView(rootView: menuView)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let menuButton = statusItem?.button {
            menuButton.image = NSImage(named: "app-icon")
            menuButton.action = #selector(menuAction)
        }
        NSApp.setActivationPolicy(.accessory)
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
        Resolver.register(AppLicenseManager(), .locked)
    }
}
