//
//  ConnectionManager+MacOS+Ext.swift
//  MagicTrackpad
//
//  Created by Mariusz Jakowienko on 22/07/2023.
//

import SwiftUI
import MultipeerConnectivity
import os
import Foundation
import Combine
import AppKit

struct CursorPosition: Codable {
    let width: CGFloat
    let height: CGFloat
}

struct MouseScroll: Codable {
    let offsetX: CGFloat
    let offsetY: CGFloat
}

struct RunningAppData: Codable, Equatable, Identifiable {
    var id: String { title }
    let title: String
    let imageData: Data?
}

struct RunningAppResponse: Codable {
    let applicationsTitle: String
    let runningApps: [RunningAppData]
}

struct WebpagesResponse: Codable {
    let webpagesTitle: String
    let webpages: [WebpageItem]
}

struct WorkspacesResponse: Codable {
    let workspacesTitle: String
    let workspaces: [WorkspaceSendableItem]
}

extension ConnectionManager: ConnectionSenable {
    var mouseLocation: NSPoint { NSEvent.mouseLocation }
    
    func subscribeForRunningApps() {
        self.observers = [
            NSWorkspace.shared.observe(\.runningApplications) { workspace, apps in
                let apps = self.getRunningApps()
                guard self.runningApps != apps, !apps.isEmpty else {
                    return
                }
                self.runningApps = apps
                self.send(runningApps: apps)
                self.send(webpages: self.webpages)
                self.send(workspaces: self.workspaces2)
            }
        ]
    }

    func getRunningApps() -> [RunningAppData] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { RunningAppData(title: $0.localizedName ?? "",
                                         imageData: try? $0.icon?.imageData(for: .png(scale: 1.0,
                                                                                      excludeGPSData: false))) }
    }

    func send(runningApps: [RunningAppData]) {
        let payload = RunningAppResponse(applicationsTitle: "applicationsTitle", runningApps: runningApps)
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(payload) else {
            return
        }
        send(data)
    }
    
    func send(webpages: [WebpageItem]) {
        let payload = WebpagesResponse(webpagesTitle: "webpagesTitle", webpages: webpages)
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(payload) else {
            return
        }
        send(data)
    }
    
    func send(workspaces: [WorkspaceItem2]) {
        let sendableWorkspaces: [WorkspaceSendableItem] = workspaces.map {
            .init(id: $0.id,
                  title: $0.title,
                  apps: $0.screens
                .flatMap { $0.apps }
                .compactMap { $0.app }
                .map { .init(id: $0.id,
                             name: $0.name,
                             path: $0.path,
                             imageData: try? NSWorkspace.shared.icon(forFile: $0.path).imageData(for: .png(scale: 0.2, excludeGPSData: false))) }
            )
        }
        let payload = WorkspacesResponse(workspacesTitle: "workspacesTitle", workspaces: sendableWorkspaces)
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(payload) else {
            return
        }
        send(data)
    }
}

extension ConnectionManager {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let webpageItem = try? JSONDecoder().decode(WebpageItem.self, from: data) {
            openWebPage(for: webpageItem)
            return
        }
        if let appItem = try? JSONDecoder().decode(AppSendableInfo.self, from: data) {
            if let app = workspaces2.flatMap({ $0.screens }).flatMap({ $0.apps }).first(where: { $0.app?.path == appItem.path }) {
                openApp(at: app.app?.path ?? "", size: app.size ?? .zero, position: app.position ?? .zero)
            }
            return
        }
        if let workspaceItem = try? JSONDecoder().decode(WorkspaceSendableItem.self, from: data) {
            if let workspace = workspaces2.first(where: { $0.id == workspaceItem.id }) {
                processWorkspace(workspace) {
                    print("Done")
                }
            }
            return
        }
        if let string = String(data: data, encoding: .utf8),
           let workspace = WorkspaceControl(rawValue: string) {
            DispatchQueue.main.async {
                switch workspace {
                case .next:
                    self.switchToNextWorkspace()
                case .prev:
                    self.switchToPreviousWorkspace()
                }
            }
        } else if let string = String(data: data, encoding: .utf8) {
            if string == "Connected - send data." {
                self.send(runningApps: self.runningApps)
                self.send(webpages: self.webpages)
                self.send(workspaces: self.workspaces2)
            } else {
                focusToApp(string)
            }
        }
    }
    
    func openWebPage(for webpageItem: WebpageItem) {
        guard let url = NSURL(string: webpageItem.webpageLink) as? URL else {
            return
        }
        NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error { print(error) }
        }
    }
    
    public func mainDisplayID() -> CGDirectDisplayID {
        return CGMainDisplayID()
    }
    
    public func moveCursor(onDisplay display: CGDirectDisplayID, toPoint point: CGPoint) {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y;
        let newLoc = CGPoint(x: mouseLoc.x + point.x, y: mouseLoc.y + point.y)
        CGDisplayMoveCursorToPoint(display, newLoc)
    }
    
    public func scrollMouse(onPoint point: CGPoint, xLines: Int, yLines: Int) {
        guard let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: CGScrollEventUnit.line, wheelCount: 2, wheel1: Int32(yLines), wheel2: Int32(xLines), wheel3: 0) else {
            return
        }
        print(point)
        scrollEvent.setIntegerValueField(CGEventField.eventSourceUserData, value: 1)
        scrollEvent.post(tap: CGEventTapLocation.cghidEventTap)
    }
    
    func processWorkspace(_ workspace: WorkspaceItem2, completion: @escaping () -> Void) {
        var screenIndex = 0

        func processNextScreen() {
            guard screenIndex < workspace.screens.count else {
                completion() // All screens processed
                return
            }

            let screen = workspace.screens[screenIndex]
            screenIndex += 1

            createNewSpace()
            processScreen(screen) {
                processNextScreen() // Move to the next screen after completion
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

    func processApp(_ app: AppInfo, size: CGSize, position: CGPoint, completion: @escaping () -> Void) {
        openApp(at: app.path, size: size, position: position, completed: completion)
    }
    
    func openApp(at path: String, size: CGSize, position: CGPoint, completed: (() -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.moveToNextWorkspace()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let url = URL(fileURLWithPath: path)
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let bundleId = self.getBundleIdentifier(forAppAtPath: path) {
                self.waitForAppLaunch(bundleIdentifier: bundleId) { app in
                    if let app, let appName = app.localizedName {
                        self.resizeAppWindow(appName: appName, width: size.width, height: size.height, screenPosition: position)
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
}


// ----

struct AddNewScreenView: View {
    let addAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Add new screen")
        }
        .frame(width: 280, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20.0)
                .fill(Color.black.opacity(0.2))
        )
        .onTapGesture {
            addAction()
        }
    }
}

enum ConfigurableScreenType {
    case singleScreen
    case splitScreenHorizontal
}

enum ConfigurableScreenTypeSize {
    case small
    case medium
    
    var padding: CGFloat {
        switch self {
        case .small:
            return 0.5
        case .medium:
            return 8.0
        }
    }
    
    var lineWidth: CGFloat {
        switch self {
        case .small:
            return 1.5
        case .medium:
            return 4.0
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 1.0
        case .medium:
            return 8.0
        }
    }
}

struct ScreenTypeContainer: Identifiable, Codable {
    let id: Int
    let size: CGSize?
    let position: CGPoint?
    let app: AppInfo?
    
    init(id: Int, size: CGSize? = nil, position: CGPoint? = nil, app: AppInfo? = nil) {
        self.id = id
        self.size = size
        self.position = position
        self.app = app
    }
}

struct ScreenTypeView: View {
    let screenType: ConfigurableScreenType
    let size: ConfigurableScreenTypeSize
    let addAction: ([ScreenTypeContainer]) -> Void
    @State var apps: [ScreenTypeContainer]
    
    var screenSize: CGSize {
        guard let test = getFrameOfScreen() else {
            return .zero
        }
        switch screenType {
        case .singleScreen:
            return .init(width: test.width, height: test.height)
        case .splitScreenHorizontal:
            return .init(width: test.width / 2, height: test.height)
        }
    }
    
    init(screenType: ConfigurableScreenType, size: ConfigurableScreenTypeSize, apps: [ScreenTypeContainer]?, addAction: @escaping ([ScreenTypeContainer]) -> Void) {
        self.apps = apps ?? [.init(id: 0), .init(id: 1)]
        self.screenType = screenType
        self.size = size
        self.addAction = addAction
    }
    
    var body: some View {
        switch screenType {
        case .singleScreen:
            cell(index: 0)
        case .splitScreenHorizontal:
            HStack {
                cell(index: 0)
                cell(index: 1)
            }
        }
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
    
    func cell(index: Int) -> some View {
        VStack {
            if let path = apps[safe: index]?.app?.path {
                ZStack {
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(Color.gray, lineWidth: size.lineWidth)
                        .padding(.all, size.padding)
                    Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                        .resizable()
                        .frame(width: 32, height: 32)
                        .cornerRadius(6)
                        .onDrag {
                            NSItemProvider(object: path as NSString)
                        }
                }
            } else {
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: size.cornerRadius)
                            .stroke(Color.gray, lineWidth: size.lineWidth)
                            .padding(.all, size.padding)
                        if size == .medium {
                            Text("Drop app here")
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(Color.black)
                )
            }
        }
        .onDrop(of: [.text], isTargeted: nil) { providers in
            providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                if let droppedString = droppedItem as? String {
                    DispatchQueue.main.async {
                        if apps[safe: index]?.app?.path != createAppFromPath(droppedString).path {
                            apps.enumerated().forEach { (index, app) in
                                if app.app?.path == createAppFromPath(droppedString).path {
                                    apps[index] = .init(id: index)
                                }
                            }
                            let position: CGPoint = index == 0 ? .init(x: 0, y: 0) : .init(x: screenSize.width, y: 0)
                            apps[index] = .init(id: index, size: screenSize, position: position, app: createAppFromPath(droppedString))
                            addAction(apps)
                        }
                    }
                }
            }
            return true
        }
    }
    
    func createAppFromPath(_ path: String) -> AppInfo {
        let appName = URL(string: path)?.deletingPathExtension().lastPathComponent ?? ""
        return .init(id: UUID().uuidString, name: appName, path: path)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

class ConfigurableScreenViewModel: ObservableObject {
    @Published var screenType: ConfigurableScreenType = .singleScreen
    var apps: [ScreenTypeContainer]?
    var addAction: ([ScreenTypeContainer]) -> Void
    var cancellables = Set<AnyCancellable>()
    
    init(apps: [ScreenTypeContainer]?, addAction: @escaping ([ScreenTypeContainer]) -> Void) {
        self.apps = apps
        self.screenType = (apps?.filter { $0.app != nil }.count ?? 0) > 1 ? .splitScreenHorizontal : .singleScreen
        self.addAction = addAction
    }
}

struct ConfigurableScreenView: View {
    @StateObject var viewModel: ConfigurableScreenViewModel
    
    init(viewModel: ConfigurableScreenViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            HStack {
                ScreenTypeView(screenType: viewModel.screenType, size: .medium, apps: viewModel.apps, addAction: viewModel.addAction)
                VStack {
                    Button {
                        viewModel.screenType = .singleScreen
                    } label: {
                        ScreenTypeView(screenType: .singleScreen, size: .small, apps: nil, addAction: { _ in})
                    }
                    .background(viewModel.screenType == .singleScreen ? Color.blue : Color.clear)
                    Button {
                        viewModel.screenType = .splitScreenHorizontal
                    } label: {
                        ScreenTypeView(screenType: .splitScreenHorizontal, size: .small, apps: nil, addAction: { _ in })
                    }
                    .background(viewModel.screenType == .splitScreenHorizontal ? Color.blue : Color.clear)
                }
                .frame(width: 45)
            }
        }
        .frame(width: 280, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20.0)
                .fill(Color.black.opacity(0.4))
        )
    }
}

class ScreenItem: Identifiable, Codable {
    let id: String
    var apps: [ScreenTypeContainer]
    
    init(id: String, apps: [ScreenTypeContainer] = []) {
        self.id = id
        self.apps = apps
    }
    
    func updateApps(_ containers: [ScreenTypeContainer]) {
        apps = containers
    }
}

class CreateWorkspaceWithMultipleScreensViewModel: ObservableObject {
    @Published var screens: [ScreenItem] = []
    @Published var title: String
    @Published var searchText: String = ""
    @Published var cancellables = Set<AnyCancellable>()
    @Published var installedApps: [AppInfo] = []
    var id: String
    
    public init(workspace: WorkspaceItem2? = nil) {
        self.screens = workspace?.screens ?? []
        self.title = workspace?.title ?? ""
        self.id = workspace?.id ?? UUID().uuidString
        registerListener()
    }
    
    func addNewScreen() {
        screens.append(.init(id: UUID().uuidString))
    }
    
    func registerListener() {
        $searchText
            .sink { [weak self] _ in
                self?.fetchInstalledApps()
            }
            .store(in: &cancellables)
    }
    
    func removeItem(with path: String) {
        screens = screens.filter { $0.id != id }
    }
    
    func save() -> WorkspaceItem2? {
        guard !title.isEmpty && !screens.isEmpty else {
            return nil
        }
        return .init(id: id, title: title, screens: screens)
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

struct CreateWorkspaceWithMultipleScreens: View {
    @ObservedObject var viewModel: CreateWorkspaceWithMultipleScreensViewModel
    
    weak var delegate: WorkspaceWindowDelegate?
    var size: Double = 100
    
    public init(viewModel: CreateWorkspaceWithMultipleScreensViewModel, delegate: WorkspaceWindowDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("New Workspace")
                    .font(.system(size: 17.0, weight: .bold))
                    .padding([.horizontal, .top], 16)
                TextField(text: $viewModel.title) {
                    Text("Name")
                        .padding()
                }
                Spacer()
                Button("Save") {
                    if let workspace = viewModel.save() {
                        delegate?.saveWorkspace2(with: workspace)
                        delegate?.close()
                    }
                }
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding([.horizontal, .top], 16.0)
            }
            Divider()
        }
        HStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240))], spacing: 6) {
                    ForEach(viewModel.screens) { screen in
                        ConfigurableScreenView(viewModel: .init(apps: screen.apps, addAction: screen.updateApps))
                    }
                    AddNewScreenView {
                        viewModel.addNewScreen()
                    }
                }
            }
            .frame(minWidth: 600, minHeight: 500)
            VStack(alignment: .leading) {
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
                                Spacer()
                            }
                            .onDrag {
                                NSItemProvider(object: app.path as NSString)
                            }
                        }
                        .padding(.vertical, 4)
                        
                    }
                    .onAppear(perform: viewModel.fetchInstalledApps)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
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
