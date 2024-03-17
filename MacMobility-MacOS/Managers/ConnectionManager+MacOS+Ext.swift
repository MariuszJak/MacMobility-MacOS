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
    
    
//    func send(runningApps: AllAppData) {
//        guard !session.connectedPeers.isEmpty,
//              let data = try? JSONEncoder().encode(runningApps) else {
//            return
//        }
//        send(data)
//    }

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
}

extension ConnectionManager {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let webpageItem = try? JSONDecoder().decode(WebpageItem.self, from: data) {
            openWebPage(for: webpageItem)
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
            } else {
                focusToApp(string)
            }
        }
    }
    
    func openWebPage(for webpageItem: WebpageItem) {
        guard let url = NSURL(string: webpageItem.webpageLink) as? URL else {
            return
        }
        NSWorkspace.shared.open([url],
                                withAppBundleIdentifier: webpageItem.browser.bundleIdentifier,
                                options: NSWorkspace.LaunchOptions.default,
                                additionalEventParamDescriptor: nil,
                                launchIdentifiers: nil)
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
}

