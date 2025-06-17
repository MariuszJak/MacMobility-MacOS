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
        Settings {
            EmptyView()
        }
    }
}

struct QAMTutorial: Codable {
    let wasSeen: Bool
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var permissionsWindow: NSWindow?
    private var welcomeWindow: NSWindow?
    private var shortcutsWindow: NSWindow?
    private var tabShortcutsWindow: NSWindow?
    private var qamTutorialWindow: NSWindow?
    private let connectionManager = ConnectionManager()
    var statusItem: NSStatusItem?
    var popOver = NSPopover()
    var menuView: MacOSMainPopoverView?
    var eventMonitor: Any?
    var cancellables = Set<AnyCancellable>()
    lazy var shortcutsViewModel: ShortcutsViewModel = .init(connectionManager: connectionManager)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        register()
        menuView = MacOSMainPopoverView(connectionManager: connectionManager) {
            self.openShortcutsWindow()
        }
        
        popOver.behavior = .transient
        popOver.animates = true
        popOver.contentViewController = NSViewController()
        popOver.contentViewController?.view = NSHostingView(rootView: menuView)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        connectionManager.$showsLocalError.receive(on: DispatchQueue.main).sink { shouldShow in
            if shouldShow, let error = self.connectionManager.localError {
                self.showGlobalAlert(title: "Alert", message: error)
            }
        }
        .store(in: &cancellables)
//        UserDefaults.standard.clear(key: .lifecycle)
//        UserDefaults.standard.clear(key: .quickActionTutorialSeen)
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
            tabShortcutsWindow?.styleMask.insert(.fullSizeContentView)
            tabShortcutsWindow?.title = "Quick Actions Drag & Drop"
            let hv = NSHostingController(rootView: StandaloneTabView(viewModel: shortcutsViewModel))
            tabShortcutsWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = tabShortcutsWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        tabShortcutsWindow?.makeKeyAndOrderFront(nil)
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
            shortcutsWindow?.styleMask.insert(.fullSizeContentView)
            shortcutsWindow?.title = "Editor"
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
            qamTutorialWindow?.styleMask.insert(.fullSizeContentView)
            let hv = NSHostingController(rootView: QuickActionVideoTutorialView())
            qamTutorialWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = qamTutorialWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        qamTutorialWindow?.makeKeyAndOrderFront(nil)
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

struct StandaloneTabView: View {
    @ObservedObject private var viewModel: ShortcutsViewModel
    @State private var tab: Tab = .apps
    @Namespace private var animation
    
    init(viewModel: ShortcutsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            AnimatedSearchBar(searchText: $viewModel.searchText)
                .padding(.all, 3.0)
            CustomTabBar(selectedTab: $tab, animation: animation) {
                viewModel.searchText = ""
            }
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            .padding(.bottom, 16.0)
            .frame(minWidth: 500.0)
            
            Group {
                switch tab {
                case .apps:
                    installedAppsView
                case .shortcuts:
                    shortcutsView
                case .webpages:
                    websitesView
                case .utilities:
                    utilitiesView
                }
            }
            .frame(maxWidth: 500.0, maxHeight: .infinity)
        }
    }
    
    private var websitesView: some View {
        WebpagesWindowView(viewModel: viewModel)
    }
    
    private var utilitiesView: some View {
        UtilitiesWindowView(viewModel: viewModel)
    }
        
    private var installedAppsView: some View {
        VStack(alignment: .leading) {
            if viewModel.installedApps.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Text("No app found.")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(Color.white)
                                .padding(.bottom, 12.0)
                            Button {
//                                if let path = selectApp() {
//                                    viewModel.addInstalledApp(for: path)
//                                }
                            } label: {
                                Text("Search in Finder")
                                    .font(.system(size: 16.0))
                                    .foregroundStyle(Color.white)
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.bottom, 8.0)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        Spacer()
                            .frame(height: 16.0)
                        ForEach(viewModel.installedApps) { app in
                            HStack {
                                HStack {
                                    HStack {
                                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.path ?? ""))
                                            .resizable()
                                            .frame(width: 46, height: 46)
                                            .cornerRadius(20.0)
                                            .padding(.trailing, 8)
                                        Text(app.title)
                                            .padding(.vertical, 6.0)
                                    }
                                    .onDrag {
                                        NSItemProvider(object: app.id as NSString)
                                    }
                                }
                                .id(app.title)
                                Spacer()
                            }
                            .cornerRadius(10)
                            .padding(.horizontal, 16.0)
                            .padding(.vertical, 6.0)
                            Divider()
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.windowBackgroundColor))
                )
        )
        .padding(.bottom, 16.0)
    }
    
    private var shortcutsView: some View {
        VStack(alignment: .leading) {
            if viewModel.shortcuts.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Text("No shortcuts found.")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(Color.white)
                                .padding(.bottom, 12.0)
                            Button {
//                                openInstallShortcutsWindow()
                            } label: {
                                Text("Add new one!")
                                    .font(.system(size: 16.0))
                                    .foregroundStyle(Color.white)
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.bottom, 8.0)
            } else {
                ScrollView {
                    Spacer()
                        .frame(height: 16.0)
                    ForEach(viewModel.shortcuts) { shortcut in
                        HStack {
                            if let data = shortcut.imageData, let image = NSImage(data: data) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .cornerRadius(20.0)
                                    .frame(width: 38, height: 38)
                            }
                            Text(shortcut.title)
                                .padding(.vertical, 6.0)
                            Spacer()
                        }
                        .onDrag {
                            NSItemProvider(object: shortcut.id as NSString)
                        }
                        .padding(.horizontal, 16.0)
                        .padding(.vertical, 6.0)
                        Divider()
                    }
                }
                .padding(.bottom, 8.0)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.windowBackgroundColor))
                )
        )
        .padding(.bottom, 16.0)
    }
}
