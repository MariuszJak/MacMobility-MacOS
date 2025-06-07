//
//  ConnectionManager+MacOS+Ext.swift
//  MacMobility
//
//  Created by CoderBlocks on 22/07/2023.
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

struct WorkspacesResponse: Codable {
    let workspacesTitle: String
    let workspaces: [WorkspaceSendableItem]
}

struct ShortcutsResponse: Codable {
    let shortcutTitle: String
    let shortcuts: [ShortcutObject]
}

struct ShortcutsResponseDiff: Codable {
    let shortcutTitle: String
    let shortcutsDiff: [ChangeType: [SDiff]]
}

struct PagesResponse: Codable {
    let title: String
    let assignedAppsToPages: [AssignedAppsToPages]
}

struct FocusResponse: Codable {
    let title: String
    let pageToFocus: AssignedAppsToPages
}

struct StartStream: Codable {
    let title: String
    let action: String
    let ipAddress: String
}

extension ConnectionManager: ConnectionSenable {
    var mouseLocation: NSPoint { NSEvent.mouseLocation }

    func getRunningApps() -> [RunningAppData] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { RunningAppData(title: $0.localizedName ?? "",
                                         imageData: try? $0.icon?.imageData(for: .png(scale: 1.0,
                                                                                      excludeGPSData: false))) }
    }
    
    func getHighResAppIcon(for app: NSRunningApplication) -> NSImage? {
        guard let bundleURL = app.bundleURL,
              let bundle = Bundle(url: bundleURL),
              let iconFile = bundle.infoDictionary?["CFBundleIconFile"] as? String else {
            return nil
        }

        let iconName = (iconFile as NSString).deletingPathExtension
        let iconExtension = (iconFile as NSString).pathExtension.isEmpty ? "icns" : (iconFile as NSString).pathExtension
        let iconPath = bundle.path(forResource: iconName, ofType: iconExtension)

        if let path = iconPath {
            return NSImage(contentsOfFile: path)
        }

        return nil
    }

    func send(runningApps: [RunningAppData]) {
        let payload = RunningAppResponse(applicationsTitle: "applicationsTitle", runningApps: runningApps)
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
    
    func send(shortcutsDiff: [ChangeType: [SDiff]]) {
        let payload = ShortcutsResponseDiff(shortcutTitle: "shortcutTitleDiff", shortcutsDiff: shortcutsDiff)
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(payload) else {
            return
        }
        send(data)
    }
    
    func send(assignedAppsToPages: [AssignedAppsToPages]) {
        let payload = PagesResponse(title: "AssignedApps", assignedAppsToPages: assignedAppsToPages)
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(payload) else {
            return
        }
        send(data)
    }
    
    func send(assignedApp: AssignedAppsToPages) {
        let payload = FocusResponse(title: "FocusResponse", pageToFocus: assignedApp)
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(payload) else {
            return
        }
        send(data)
    }
    
    func sendStartStream(action: String, ipAddress: String) {
        let payload = StartStream(title: "MacMobilityStream", action: action, ipAddress: ipAddress)
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(payload) else {
            return
        }
        send(data)
    }
    
    func send(alert: AlertMessage) {
        let payload = AlertMessageResponse(alertTitle: "alertTitle", message: alert)
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(payload) else {
            return
        }
        send(data)
    }
    
    func getLocalIPAddress() -> String? {
        var address: String?

        // Get list of all interfaces
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family

                // Check for IPv4
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    // Skip internal interfaces like lo0
                    if name == "en0" || name.hasPrefix("en") {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        let result = getnameinfo(interface.ifa_addr,
                                                 socklen_t(interface.ifa_addr.pointee.sa_len),
                                                 &hostname,
                                                 socklen_t(hostname.count),
                                                 nil,
                                                 0,
                                                 NI_NUMERICHOST)
                        if result == 0 {
                            address = String(cString: hostname)
                            break
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }
}

struct AlertMessageResponse: Codable {
    let alertTitle: String
    let message: AlertMessage
}


struct AlertMessage: Codable {
    let title: String
    let message: String
}
