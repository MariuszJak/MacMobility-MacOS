//
//  WorkspacesWindowView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 27/02/2025.
//

import SwiftUI

struct AppInfo: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    
    public init(id: String, name: String, path: String) {
        self.id = id
        self.name = name
        self.path = path
    }
}

struct WorkspaceItem: Identifiable, Codable {
    var id: String
    let title: String
    let screens: [ScreenItem]
}

struct AppSendableInfo: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let imageData: Data?
    
    public init(id: String, name: String, path: String, imageData: Data?) {
        self.id = id
        self.name = name
        self.path = path
        self.imageData = imageData
    }
}

struct WorkspaceSendableItem: Identifiable, Codable {
    var id: String
    let title: String
    let apps: [AppSendableInfo]
    
    public init(id: String, title: String, apps: [AppSendableInfo]) {
        self.id = id
        self.title = title
        self.apps = apps
    }
}

protocol WorkspaceWindowDelegate: AnyObject {
    func saveWorkspace(with item: WorkspaceItem)
    var close: () -> Void { get }
}

struct WorkspacesWindowView: View, AppleScriptCommandable {
    @State private var screenIndex = 0
    @State private var newWindow: NSWindow?
    @State private var allBrowserwWindow: NSWindow?
    @State private var inProgressWindow: NSWindow?
    @State private var installedApps: [AppInfo] = []
    @StateObject var viewModel: WorkspacesWindowViewModel
    let connectionManager: ConnectionManager
    let closeAction: () -> Void
    
    init(connectionManager: ConnectionManager, closeAction: @escaping () -> Void) {
        self.connectionManager = connectionManager
        self.closeAction = closeAction
        self._viewModel = .init(wrappedValue: .init(connectionManager: connectionManager))
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Workspaces")
                            .font(.system(size: 17.0, weight: .bold))
                            .padding([.horizontal, .top], 16)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .onTapGesture {
                                openCreateNewWorkspaceWindow()
                            }
                            .padding([.horizontal, .top], 16.0)
                    }
                    Divider()
                    if !viewModel.workspaces.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240))], spacing: 6) {
                                ForEach(viewModel.workspaces) { workspace in
                                    VStack(alignment: .leading) {
                                        VStack(alignment: .leading) {
                                            HStack(alignment: .top) {
                                                Text(workspace.title)
                                                    .lineLimit(1)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .padding(.bottom, 8)
                                            }
                                            apps(in: workspace)
                                            Divider()
                                            HStack {
                                                Image(systemName: "arrow.up.right.square")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
                                                        processWorkspace(workspace) {
                                                            DispatchQueue.main.async {
                                                                inProgressWindow?.close()
                                                            }
                                                        }
                                                        appOpeningInProgressWindow()
                                                        closeAction()
                                                    }
                                                Image(systemName: "gear")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
                                                        openCreateNewWorkspaceWindow(workspace)
                                                    }
                                                Image(systemName: "trash")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
                                                        viewModel.removeWorkspace2(with: workspace)
                                                    }
                                                Spacer()
                                            }
                                        }
                                        .padding(.all, 10)
                                    }
                                    .padding(.all, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .scrollIndicators(.hidden)
                        .padding(.top, 16.0)
                    } else {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack {
                                    Text("No workspaces found.")
                                        .font(.system(size: 24, weight: .medium))
                                        .padding(.bottom, 12.0)
                                    Button {
                                        openCreateNewWorkspaceWindow()
                                    } label: {
                                        Text("Add new one!")
                                            .font(.system(size: 16.0))
                                    }
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func apps(in workspace: WorkspaceItem) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 30))], spacing: 2) {
            ForEach(workspace.screens) { screen in
                ForEach(screen.apps) { test in
                    if let app = test.app {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                            .resizable()
                            .frame(width: 38, height: 38)
                            .cornerRadius(3)
                            .onTapGesture {
                                openApp(at: app.path)
                                closeAction()
                            }
                    }
                }
            }
        }
        .padding(.bottom, 20.0)
    }
    
    func processWorkspace(_ workspace: WorkspaceItem, completion: @escaping () -> Void) {
        screenIndex = 0

        func processNextScreen() {
            if screenIndex == -1 {
                screenIndex = 0
                completion()
                return
            }
            guard screenIndex < workspace.screens.count else {
                completion()
                return
            }

            let screen = workspace.screens[screenIndex]
            screenIndex += 1

            createNewSpace()
            processScreen(screen) {
                processNextScreen()
            }
        }

        processNextScreen()
    }

    func processScreen(_ screen: ScreenItem, completion: @escaping () -> Void) {
        let screenApps = screen.apps // Get all ScreenTypeContainers
        var pendingApps = screenApps.count

        guard pendingApps > 0 else {
            completion() // No apps in this screen, move to next
            return
        }

        for container in screenApps {
            if let app = container.app {
                processApp(app, size: container.size ?? .zero, position: container.position ?? .zero) {
                    pendingApps -= 1
                    if pendingApps == 0 {
                        completion()
                    }
                }
            } else {
                pendingApps -= 1
                if pendingApps == 0 {
                    completion()
                }
            }
        }
    }
    
    func openApp(at path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }

    func processApp(_ app: AppInfo, size: CGSize, position: CGPoint, completion: @escaping () -> Void) {
        openApp(at: app.path, size: size, position: position, completed: completion)
    }
    
    func openApp(at path: String, size: CGSize, position: CGPoint, completed: (() -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            moveToNextWorkspace()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let url = URL(fileURLWithPath: path)
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let bundleId = getBundleIdentifier(forAppAtPath: path) {
                waitForAppLaunch(bundleIdentifier: bundleId) { app in
                    if let app, let appName = app.localizedName {
                        resizeAppWindow(appName: appName, width: size.width, height: size.height, screenPosition: position)
                    }
                    completed?()
                }
            }
        }
    }
    
    func resizeAppWindow(appName: String, width: CGFloat, height: CGFloat, screenPosition: CGPoint) {
        if !isAppInCurrentSpace(appName: appName) {
            switchToAppWorkspace(appName: appName)
            sleep(1)
        }
        
        let type = CGWindowListOption.optionOnScreenOnly
        let windowList = CGWindowListCopyWindowInfo(type, kCGNullWindowID) as NSArray? as? [[String: AnyObject]]
        
        for entry  in windowList! {
            let owner = entry[kCGWindowOwnerName as String] as! String
            _ = entry[kCGWindowBounds as String] as? [String: Int]
            let pid = entry[kCGWindowOwnerPID as String] as? Int32
            
            if owner == appName {
                let appRef = AXUIElementCreateApplication(pid!)
                
                var value: AnyObject?
                _ = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value)
                
                if let windowList = value as? [AXUIElement] { print ("windowList #\(windowList)")
                    if let _ = windowList.first {
                        var position : CFTypeRef
                        var size : CFTypeRef
                        var newPoint = CGPoint(x: screenPosition.x, y: screenPosition.y)
                        var newSize = CGSize(width: width, height: height)
                        
                        position = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!,&newPoint)!;
                        AXUIElementSetAttributeValue(windowList.first!, kAXPositionAttribute as CFString, position);
                        
                        size = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!,&newSize)!;
                        AXUIElementSetAttributeValue(windowList.first!, kAXSizeAttribute as CFString, size);
                    }
                }
            }
        }
    }
    
    func moveToNextWorkspace() {
        let script = """
        tell application "System Events" to key code 124 using {control down}
        """
        execute(script)
    }
    
    func createNewSpace() {
        let script = """
        do shell script "open -a 'Mission Control'"
        delay 0.2
        tell application "System Events" to ¬
            click (every button whose value of attribute "AXDescription" is "add desktop") ¬
                of UI element "Spaces Bar" of UI element 1 of group 1 of process "Dock"
        delay 0.2
        do shell script "open -a 'Mission Control'"
        """
        
        execute(script)
    }
    
    func getBundleIdentifier(forAppAtPath appPath: String) -> String? {
        let appBundle = Bundle(path: appPath)
        return appBundle?.bundleIdentifier
    }
    
    func waitForAppLaunch(bundleIdentifier: String, completion: @escaping (NSRunningApplication?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            while true {
                if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
                    DispatchQueue.main.async {
                        completion(app)
                    }
                    return
                }
                usleep(500_000)
            }
        }
    }
    
    func getAppWindows(appName: String) -> [AXUIElement] {
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.localizedName == appName }) else {
            print("App not found")
            return []
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)

        if result != .success {
            print("Failed to get windows")
            return []
        }

        return value as? [AXUIElement] ?? []
    }

    func getWindowPosition(_ window: AXUIElement) -> CGPoint? {
        var positionValue: AnyObject?
        if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success {
            var point = CGPoint()
            let pos = positionValue as! AXValue
            if AXValueGetValue(pos, AXValueType.cgPoint, &point) {
                return point
            }
        }
        return nil
    }

    // Check if the app is in the current space
    func isAppInCurrentSpace(appName: String) -> Bool {
        let windows = getAppWindows(appName: appName)
        
        for window in windows {
            if let pos = getWindowPosition(window) {
                let screens = NSScreen.screens
                for screen in screens {
                    if screen.frame.contains(pos) {
                        print("\(appName) is in the current space.")
                        return true
                    }
                }
            }
        }

        print("\(appName) is NOT in the current space.")
        return false
    }
    
    func switchToAppWorkspace(appName: String) {
        let script = """
        tell application "System Events"
            tell process "\(appName)"
                perform action "AXRaise" of window 1
            end tell
        end tell
        """
        
        execute(script)
    }
    
    func getFrameOfScreen() -> NSRect? {
        if let window = NSApplication.shared.mainWindow {
            if let screen = window.screen {
                let screenFrame = screen.frame
                return screenFrame
            }
        }
        return nil
    }
    
    private func appOpeningInProgressWindow() {
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 140
        if nil == inProgressWindow {
            let screenFrame = getFrameOfScreen() ?? .zero
            
            let windowX = (screenFrame.width - windowWidth) / 2
            let windowY = (screenFrame.height - windowHeight) / 2
            inProgressWindow = NSWindow(
                contentRect: NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            inProgressWindow?.center()
            inProgressWindow?.setFrameAutosaveName("In Progress")
            inProgressWindow?.isReleasedWhenClosed = false
            inProgressWindow?.titlebarAppearsTransparent = true
            inProgressWindow?.styleMask.insert(.fullSizeContentView)
            
            inProgressWindow?.level = .floating
            inProgressWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: inProgressWindow) else {
                return
            }
            let test = InProgressView(width: windowWidth, height: windowHeight) {
                screenIndex = -1
            }
            inProgressWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: test)
            inProgressWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = inProgressWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        inProgressWindow?.contentView = NSHostingView(rootView: InProgressView(width: windowWidth, height: windowHeight) {
            screenIndex = -1
        })
        inProgressWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openCreateNewWorkspaceWindow(_ item: WorkspaceItem? = nil) {
        if nil == newWindow {
            newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("New Workspace")
            newWindow?.isReleasedWhenClosed = false
            newWindow?.titlebarAppearsTransparent = true
            newWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: newWindow) else {
                return
            }
            let test = CreateWorkspaceWithMultipleScreens(viewModel: .init(workspace: item), delegate: viewModel)
            newWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: test)
            newWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = newWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            
            viewModel.close = {
                newWindow?.close()
            }
            
            NotificationCenter.default.addObserver(
                   forName: NSWindow.willCloseNotification,
                   object: newWindow,
                   queue: .main
               ) { _ in
                   test.viewModel.screens.removeAll()
               }
        }
        newWindow?.contentView = NSHostingView(rootView: CreateWorkspaceWithMultipleScreens(viewModel: .init(workspace: item), delegate: viewModel))
        newWindow?.makeKeyAndOrderFront(nil)
    }
}

struct InProgressView: View {
    let width: CGFloat
    let height: CGFloat
    let cancelAction: () -> Void
    @State var didCancel = false
    
    var body: some View {
        VStack {
            HStack {
                Text(didCancel ? "Cancelling..." : "Opening apps in Progress")
                ProgressView()
                    .progressViewStyle(.circular)
            }
            Button("Cancel") {
                didCancel = true
                cancelAction()
            }
        }
        .frame(width: width, height: height)
    }
}

struct RedXButton: View {
    var action: () -> Void
    
    var body: some View {
        Image(systemName: "xmark")
            .frame(width: 25, height: 25)
            .background(Color.red)
            .clipShape(Circle())
            .shadow(radius: 5.0)
            .onTapGesture {
                action()
            }
    }
}
