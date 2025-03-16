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

struct ShortcutsResponse: Codable {
    let shortcutTitle: String
    let shortcuts: [ShortcutObject]
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
    
    func send(shortcuts: [ShortcutObject]) {
        let payload = ShortcutsResponse(shortcutTitle: "shortcutTitle", shortcuts: shortcuts)
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(payload) else {
            return
        }
        send(data)
    }
}
