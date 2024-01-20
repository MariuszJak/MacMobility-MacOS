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

extension ConnectionManager: ConnectionSenable {
    var mouseLocation: NSPoint { NSEvent.mouseLocation }
    
    func subscribeForRunningApps() {
        self.observers = [
            NSWorkspace.shared.observe(\.runningApplications) { workspace, apps in
                let apps = self.getRunningApps()
                guard self.runningApps != apps else {
                    return
                }
                self.runningApps = apps
                self.send(runningApps: apps)
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
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(runningApps) else {
            return
        }
        send(data)
    }
}

extension ConnectionManager {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let position = try? JSONDecoder().decode(CursorPosition.self, from: data) {
            moveCursor(onDisplay: mainDisplayID(),
                       toPoint: CGPoint(x: position.width,
                                        y: position.height))
            return
        }
        if let mouseScroll = try? JSONDecoder().decode(MouseScroll.self, from: data) {
            scrollMouse(onPoint: .init(x: mouseScroll.offsetX, y: mouseScroll.offsetY), xLines: 1, yLines: -1)
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
            } else {
                focusToApp(string)
            }
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
}

