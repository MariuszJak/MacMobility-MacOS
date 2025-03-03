//
//  WorkspacesWindowView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 27/02/2025.
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
    let apps: [AppInfo]
}

// ---

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

// ---

protocol WorkspaceWindowDelegate: AnyObject {
    func saveWorkspace(with item: WorkspaceItem)
    var close: () -> Void { get }
}

struct WorkspacesWindowView: View, AppleScriptCommandable {
    @State private var newWindow: NSWindow?
    @State private var allBrowserwWindow: NSWindow?
    @State private var installedApps: [AppInfo] = []
    @State var currentIndex = 0
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
                                            HStack(spacing: 4) {
                                                ForEach(workspace.apps) { app in
                                                    Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                                                        .resizable()
                                                        .frame(width: 38, height: 38)
                                                        .cornerRadius(3)
                                                        .onTapGesture {
                                                            openApp(at: app.path, inNewWorkspace: false)
                                                            closeAction()
                                                        }
                                                }
                                            }
                                            .padding(.bottom, 20.0)
                                            Divider()
                                            HStack {
                                                Image(systemName: "arrow.up.right.square")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
                                                        currentIndex = 0
                                                        recursivelyOpenMultipleApps(workspace)
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
                                                        viewModel.removeWorkspace(with: workspace)
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
    
    func recursivelyOpenMultipleApps(_ workspace: WorkspaceItem) {
//        connectionManager.recursivelyOpenMultipleApps(workspace)
        let limit = workspace.apps.count
        
        openApp(at: workspace.apps[currentIndex].path) {
            currentIndex += 1
            if currentIndex >= limit {
                currentIndex = 0
                return
            }
            recursivelyOpenMultipleApps(workspace)
        }
    }
    
    func openApp(at path: String, inNewWorkspace: Bool = true, completed: (() -> Void)? = nil) {
//        connectionManager.openApp(at: path, inNewWorkspace: inNewWorkspace, completed: completed)
        if inNewWorkspace {
            createNewSpace()
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
                            resizeAppWindow(appName: appName, width: 1920, height: 1080)
                        }
                        completed?()
                    }
                }
            }
        } else {
            let url = URL(fileURLWithPath: path)
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
    }
    
    func resizeAppWindow(appName: String, width: CGFloat, height: CGFloat) {
//        connectionManager.resizeAppWindow(appName: appName, width: width, height: height)
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
                        var newPoint = CGPoint(x: 0, y: 0)
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
//        connectionManager.moveToNextWorkspace()
        let script = """
        tell application "System Events" to key code 124 using {control down}
        """
        execute(script)
    }
    
    func createNewSpace() {
//        connectionManager.createNewSpace()
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
//        connectionManager.getBundleIdentifier(forAppAtPath: appPath)
        let appBundle = Bundle(path: appPath)
        return appBundle?.bundleIdentifier
    }
    
    func waitForAppLaunch(bundleIdentifier: String, completion: @escaping (NSRunningApplication?) -> Void) {
//        connectionManager.waitForAppLaunch(bundleIdentifier: bundleIdentifier, completion: completion)
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
//        connectionManager.getAppWindows(appName: appName)
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
//        connectionManager.getWindowPosition(window)
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
//        connectionManager.isAppInCurrentSpace(appName: appName)
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
//        connectionManager.switchToAppWorkspace(appName: appName)
        let script = """
        tell application "System Events"
            tell process "\(appName)"
                perform action "AXRaise" of window 1
            end tell
        end tell
        """
        
        execute(script)
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
            let test = CreateWorkspace(viewModel: .init(workspace: item), delegate: viewModel)
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
                   test.viewModel.items.removeAll()
               }
        }
        newWindow?.contentView = NSHostingView(rootView: CreateWorkspace(viewModel: .init(workspace: item), delegate: viewModel))
        newWindow?.makeKeyAndOrderFront(nil)
    }
}

class CreateWorkspaceViewModel: ObservableObject {
    @Published var items: [AppInfo]
    @Published var title: String
    @Published var searchText: String = ""
    @Published var cancellables = Set<AnyCancellable>()
    @Published var installedApps: [AppInfo] = []
    var id: String
    
    public init(workspace: WorkspaceItem? = nil) {
        self.items = workspace?.apps ?? []
        self.title = workspace?.title ?? ""
        self.id = workspace?.id ?? UUID().uuidString
        registerListener()
    }
    
    func registerListener() {
        $searchText
            .sink { [weak self] _ in
                self?.fetchInstalledApps()
            }
            .store(in: &cancellables)
    }
    
    func removeItem(with path: String) {
        items = items.filter { $0.path != path }
    }
    
    func save() -> WorkspaceItem? {
        guard !title.isEmpty && !items.isEmpty else {
            return nil
        }
        return .init(id: id, title: title, apps: items)
    }
    
    func fetchInstalledApps() {
        let appDirectories = [
            "/Applications",
            "/System/Applications/Utilities"
        ]

        var apps: [AppInfo] = []

        for directory in appDirectories {
            apps.append(contentsOf: findApps(in: directory))
        }

        DispatchQueue.main.async {
            if self.searchText.isEmpty {
                self.installedApps = apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
            } else {
                self.installedApps = apps.sorted { $0.name.lowercased() < $1.name.lowercased() }.filter { $0.name.contains(self.searchText) }
            }
        }
    }
    
    func findApps(in directory: String) -> [AppInfo] {
        var apps: [AppInfo] = []

        if let appURLs = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for appURL in appURLs where appURL.pathExtension == "app" {
                let appName = appURL.deletingPathExtension().lastPathComponent
                apps.append(AppInfo(id: UUID().uuidString, name: appName, path: appURL.path))
            }
        }

        return apps
    }
}

import Combine

struct CreateWorkspace: View {
    @ObservedObject var viewModel: CreateWorkspaceViewModel
    
    
    weak var delegate: WorkspaceWindowDelegate?
    var size: Double = 100
    
    public init(viewModel: CreateWorkspaceViewModel, delegate: WorkspaceWindowDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    var body: some View {
        HStack {
            VStack {
                Text("Create new workspace")
                    .font(.system(size: 24.0, weight: .bold))
                    .padding()
                VStack(alignment: .leading) {
                    Text("Name your workspace")
                    TextField(text: $viewModel.title) {
                        Text("Name")
                            .padding()
                    }
                }
                .padding(.bottom, 16.0)
                Spacer()
                if viewModel.items.isEmpty {
                    Text("Drag & Drop apps")
                        .background(
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 200, height: 200)
                        )
                        .frame(width: 200, height: 200)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: size))], spacing: 8) {
                            ForEach(viewModel.items) { app in
                                ZStack {
                                    VStack {
                                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                                            .resizable()
                                            .frame(width: 64, height: 64)
                                            .cornerRadius(6)
                                        Text(app.name)
                                            .multilineTextAlignment(.center)
                                            .font(.headline)
                                    }
                                    .frame(width: 150, height: 100)
                                    HStack {
                                        Spacer().frame(width: 50.0)
                                        RedXButton {
                                            viewModel.removeItem(with: app.path)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .scrollIndicators(.hidden)
                    .frame(minWidth: 350, maxHeight: 350)
                    .background(Color.black.cornerRadius(20.0).opacity(0.8))
                    Spacer()
                    VStack(alignment: .center) {
                        Button {
                            if let workspace = viewModel.save() {
                                delegate?.saveWorkspace(with: workspace)
                                delegate?.close()
                            }
                        } label: {
                            Text("Save")
                                .font(.system(size: 12.0))
                        }
                    }
                    Spacer()
                }
            }
            .onDrop(of: [.text], isTargeted: nil) { providers in
                providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                    if let droppedString = droppedItem as? String {
                        DispatchQueue.main.async {
                            if viewModel.items.count < 6 {
                                if !viewModel.items.contains(where: { $0.path == createAppFromPath(droppedString).path }) {
                                    viewModel.items.append(createAppFromPath(droppedString))
                                }
                                
                            } else {
                                print("ERROR")
                            }
                        }
                    }
                }
                return true
            }
            VStack {
                TextField("Search...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 16.0)
                ScrollView {
                    ForEach(viewModel.installedApps) { app in
                        HStack {
                            HStack {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .cornerRadius(6)
                                Text(app.name)
                                    .font(.headline)
                            }
                            .onDrag {
                                NSItemProvider(object: app.path as NSString)
                            }
                            
                            Spacer()
                            
                            Button("Launch") {
                                openApp(at: app.path)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.trailing, 22.0)
                        }
                        .padding(.vertical, 4)
                        
                    }
                    .onAppear(perform: viewModel.fetchInstalledApps)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 200)
        .padding()
    }
    
    func createAppFromPath(_ path: String) -> AppInfo {
        let appName = URL(string: path)?.deletingPathExtension().lastPathComponent ?? ""
        return .init(id: UUID().uuidString, name: appName, path: path)
    }
    
    func openApp(at path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
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
