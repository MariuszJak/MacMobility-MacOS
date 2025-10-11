//
//  MacMobility_MacOSApp.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 20/01/2024.
//

import SwiftUI
import Combine

@main
struct MacMobility_MacOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
}

struct QAMTutorial: Codable {
    let wasSeen: Bool
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var responder = HotKeyResponder.shared
    private var permissionsWindow: NSWindow?
    private var circularWindow: NSWindow?
    private var welcomeWindow: NSWindow?
    private var shortcutsWindow: NSWindow?
    private var tabShortcutsWindow: NSWindow?
    private var qamTutorialWindow: NSWindow?
    private var newQamTutorialWindow: NSWindow?
    private let connectionManager = ConnectionManager()
    var statusItem: NSStatusItem?
    var popOver = NSPopover()
    var menuView: MacOSMainPopoverView?
    var eventMonitor: Any?
    var cancellables = Set<AnyCancellable>()
    lazy var shortcutsViewModel: ShortcutsViewModel = .init(connectionManager: connectionManager)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        register()
        closeInitialSystemWindows()
        menuView = MacOSMainPopoverView(connectionManager: connectionManager) {
            self.openShortcutsWindow()
        }
        
        popOver.behavior = .transient
        popOver.animates = true
        popOver.appearance = NSAppearance(named: .darkAqua)
        popOver.contentViewController = NSViewController()
        popOver.contentViewController?.view = NSHostingView(rootView: menuView)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        connectionManager.$showsLocalError.receive(on: DispatchQueue.main).sink { shouldShow in
            if shouldShow, let error = self.connectionManager.localError {
                self.showGlobalAlert(title: "Alert", message: error)
            }
        }
        .store(in: &cancellables)
//        UserDefaults.standard.clearAll(except: [.license, .licenseKey])
        let lifecycle: Lifecycle = UserDefaults.standard.get(key: .lifecycle) ?? .init(openCount: 0)
        if lifecycle.openCount == 0 {
            openWelcomeWindow()
            UserDefaults.standard.store(QAMTutorial(wasSeen: true), for: .quickActionTutorialSeen)
            UserDefaults.standard.store(Lifecycle(openCount: lifecycle.openCount + 1), for: .lifecycle)
        }
        if lifecycle.openCount == 1 {
            openShortcutsWindow()
            UserDefaults.standard.store(Lifecycle(openCount: lifecycle.openCount + 1), for: .lifecycle)
        }
        if lifecycle.openCount > 1 {
            openShortcutsWindow()
        }
        let qamTutorial: QAMTutorial? = UserDefaults.standard.get(key: .quickActionTutorialSeen)
        if qamTutorial == nil {
            openQAMTutorialWindow()
            UserDefaults.standard.store(QAMTutorial(wasSeen: true), for: .quickActionTutorialSeen)
        } else if let qamTutorial, !qamTutorial.wasSeen {
            openQAMTutorialWindow()
            UserDefaults.standard.store(QAMTutorial(wasSeen: true), for: .quickActionTutorialSeen)
        }
        
        if let menuButton = statusItem?.button {
            menuButton.image = NSImage(named: "app-icon")
            menuButton.action = #selector(menuAction)
        }
        NSApp.setActivationPolicy(.accessory)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openShortcuts),
            name: .openShortcuts,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closeShortcuts),
            name: .closeShortcuts,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openQAM),
            name: .openQAM,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openNewQAMTutorial),
            name: .openNewQAMTutorial,
            object: nil
        )
        setupKeyboardListener()
    }
    
    func closeInitialSystemWindows() {
        NSApp.windows[safe: 0]?.close()
    }
    
    @objc func openNewQAMTutorial() {
        openNewQAMTutorialWindow(isFirstOpen: false)
        circularWindow?.close()
        circularWindow = nil
    }
    
    func setupKeyboardListener() {
        guard !connectionManager.listenerAdded else { return }
        HotKeyManager.shared.registerHotKey()
        
        responder
            .$showWindow
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                if value {
                    let newQuickActionTutorialSeen = UserDefaults.standard.get(key: .newQuickActionTutorialSeen) ?? false
                    if newQuickActionTutorialSeen {
                        self?.openCircularWindow()
                    } else {
                        self?.openNewQAMTutorialWindow(isFirstOpen: true)
                        UserDefaults.standard.store(true, for: .newQuickActionTutorialSeen)
                    }
//                    self?.openNewQAMTutorialWindow(isFirstOpen: true)
                }
            }
            .store(in: &cancellables)
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return }
            guard let window = circularWindow else { return }

            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = window.frame

            if !windowFrame.contains(mouseLocation) {
                circularWindow?.close()
                circularWindow = nil
                NotificationCenter.default.post(
                    name: .closeShortcuts,
                    object: nil,
                    userInfo: nil
                )
            }
        }
        connectionManager.listenerAdded = true
    }
    
    @objc func openQAM() {
        openCircularWindow()
    }
    
    func openCircularWindow() {
        circularWindow?.close()
        circularWindow = nil
        if nil == circularWindow {
            circularWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 380),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            circularWindow?.center()
            circularWindow?.isReleasedWhenClosed = false
            circularWindow?.titleVisibility = .hidden
            circularWindow?.titlebarAppearsTransparent = true
            circularWindow?.isOpaque = false
            circularWindow?.backgroundColor = .clear
            circularWindow?.hasShadow = false
            circularWindow?.isMovableByWindowBackground = true
            circularWindow?.level = .floating
            let hostingController = NSHostingController(
                rootView: QuickActionsView(
                    viewModel: .init(
                        items: shortcutsViewModel.quickActionItems,
                        allItems: shortcutsViewModel.allObjects()
                    ),
                    action: { [weak self] item in
                        guard let self else { return }
                        connectionManager.runShortuct(for: item)
                        circularWindow?.close()
                        circularWindow = nil
                    }, update: { [weak self] items in
                        guard let self else { return }
                        shortcutsViewModel.saveQuickActionItems(items)
                    }, close: { [weak self] in
                        self?.closeShortcuts()
                        self?.circularWindow?.close()
                        self?.circularWindow = nil
                    }
                )
            )
            circularWindow?.contentView = hostingController.view
            positionWindowAtMouse(window: circularWindow, size: 380)
            circularWindow?.makeKeyAndOrderFront(nil)
            return
        }
        circularWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc func openShortcuts() {
        tabShortcutsWindow?.close()
        tabShortcutsWindow = nil
        if nil == tabShortcutsWindow {
            tabShortcutsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 800),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            tabShortcutsWindow?.center()
            tabShortcutsWindow?.setFrameAutosaveName("TabShortcutsWindow")
            tabShortcutsWindow?.isReleasedWhenClosed = false
            tabShortcutsWindow?.titlebarAppearsTransparent = true
            tabShortcutsWindow?.appearance = NSAppearance(named: .darkAqua)
            tabShortcutsWindow?.styleMask.insert(.fullSizeContentView)
            tabShortcutsWindow?.title = "Quick Actions Drag & Drop"
            let hv = NSHostingController(rootView: StandaloneTabView(viewModel: shortcutsViewModel))
            tabShortcutsWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = tabShortcutsWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            positionSubmenu(window: tabShortcutsWindow, size: 580)
        }
        tabShortcutsWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func positionSubmenu(window: NSWindow?, size: CGFloat) {
        guard let window, let circularWindow, let screenSize = currentScreenSize() else {
            return
        }
        let circularWindowLocation = circularWindow.frame.origin
        var offset = 0.0
        
        if circularWindowLocation.x > screenSize.width * 0.5 {
            offset = -550.0
        } else {
            offset = 450.0
        }
        
        window.setFrameOrigin(.init(x: circularWindowLocation.x + offset, y: circularWindowLocation.y))
    }
    
    private func currentScreenSize() -> CGSize? {
        let mouseLocation = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
            return screen.frame.size
        }
        return nil
    }
    
    private func positionWindowAtMouse(window: NSWindow?, size: CGFloat) {
        guard let window else {
            return
        }
        let mouseLocation = NSEvent.mouseLocation

        // Flip Y-coordinate relative to that screen
        let origin = CGPoint(
            x: mouseLocation.x - (size / 2),
            y: mouseLocation.y - size / 2
        )

        window.setFrameOrigin(origin)
    }
    
    @objc func closeShortcuts() {
        shortcutsViewModel.searchText = ""
        tabShortcutsWindow?.close()
        tabShortcutsWindow = nil
    }
    
    func showGlobalAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Dismiss")
        alert.alertStyle = .informational

        if let window = NSApp.mainWindow {
            alert.beginSheetModal(for: window) { response in
                self.performDismissAction()
            }
        } else {
            // Fallback if no window available
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                performDismissAction()
            }
        }
    }

    func performDismissAction() {
        connectionManager.showsLocalError = false
    }
    
    func openShortcutsWindow() {
        shortcutsWindow?.close()
        shortcutsWindow = nil
        if nil == shortcutsWindow {
            shortcutsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1300, height: 700),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            shortcutsWindow?.center()
            shortcutsWindow?.setFrameAutosaveName("Shortcuts")
            shortcutsWindow?.isReleasedWhenClosed = false
            shortcutsWindow?.titlebarAppearsTransparent = true
            shortcutsWindow?.appearance = NSAppearance(named: .darkAqua)
            shortcutsWindow?.styleMask.insert(.fullSizeContentView)
            shortcutsWindow?.title = "Editor"
            shortcutsWindow?.appearance = NSAppearance(named: .darkAqua)
            let hv = NSHostingController(rootView: ShortcutsView(viewModel: shortcutsViewModel))
            shortcutsWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = shortcutsWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        shortcutsWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openQAMTutorialWindow() {
        qamTutorialWindow?.close()
        shortcutsWindow = nil
        if nil == qamTutorialWindow {
            qamTutorialWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            qamTutorialWindow?.center()
            qamTutorialWindow?.setFrameAutosaveName("QamTutorialWindow")
            qamTutorialWindow?.isReleasedWhenClosed = false
            qamTutorialWindow?.titlebarAppearsTransparent = true
            qamTutorialWindow?.appearance = NSAppearance(named: .darkAqua)
            qamTutorialWindow?.styleMask.insert(.fullSizeContentView)
            let hv = NSHostingController(rootView: QuickActionVideoTutorialView())
            qamTutorialWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = qamTutorialWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        qamTutorialWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openNewQAMTutorialWindow(isFirstOpen: Bool) {
        newQamTutorialWindow?.close()
        newQamTutorialWindow = nil
        if nil == newQamTutorialWindow {
            newQamTutorialWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 700),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newQamTutorialWindow?.center()
            newQamTutorialWindow?.setFrameAutosaveName("NewQamTutorialWindow")
            newQamTutorialWindow?.isReleasedWhenClosed = false
            newQamTutorialWindow?.titlebarAppearsTransparent = true
            newQamTutorialWindow?.appearance = NSAppearance(named: .darkAqua)
            newQamTutorialWindow?.styleMask.insert(.fullSizeContentView)
            let hv = NSHostingController(rootView: NewQAMVideoTutorialView(isFirstOpen: isFirstOpen){
                self.newQamTutorialWindow?.close()
                self.newQamTutorialWindow = nil
            })
            newQamTutorialWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = newQamTutorialWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        newQamTutorialWindow?.makeKeyAndOrderFront(nil)
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
            welcomeWindow?.appearance = NSAppearance(named: .darkAqua)
            welcomeWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: welcomeWindow) else {
                return
            }
            
            welcomeWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: WelcomeView(viewModel: .init(closeAction: { setupMode, automatedActions, websites, createMultiactions, browser in
                self.connectionManager.createMultiactions = createMultiactions
                self.connectionManager.browser = browser
                self.connectionManager.websites = websites
                self.connectionManager.initialSetup = setupMode
                self.connectionManager.automatedActions = automatedActions
                self.welcomeWindow?.close()
                self.openShortcutsWindow()
            }), connectionManager: connectionManager))
            welcomeWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = welcomeWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        welcomeWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openPermissionsWindow() {
        if nil == permissionsWindow {
            permissionsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
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
