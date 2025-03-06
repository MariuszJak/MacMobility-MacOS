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
                self.send(workspaces: self.workspaces)
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
    
    func send(workspaces: [WorkspaceItem]) {
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
            if let app = workspaces.flatMap({ $0.screens }).flatMap({ $0.apps }).first(where: { $0.app?.path == appItem.path }) {
                openApp(at: app.app?.path ?? "", size: app.size ?? .zero, position: app.position ?? .zero)
            }
            return
        }
        if let workspaceItem = try? JSONDecoder().decode(WorkspaceSendableItem.self, from: data) {
            if let workspace = workspaces.first(where: { $0.id == workspaceItem.id }) {
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
                self.send(workspaces: self.workspaces)
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
    
    func processWorkspace(_ workspace: WorkspaceItem, completion: @escaping () -> Void) {
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
