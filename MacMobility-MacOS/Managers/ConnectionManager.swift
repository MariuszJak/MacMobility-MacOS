//
//  ConnectionManager.swift
//  MagicTrackpad
//
//  Created by CoderBlocks on 22/07/2023.
//

import SwiftUI
import MultipeerConnectivity
import os
import Foundation
import Combine
import AppKit
import IOKit.pwr_mgt

enum PairingStatus: Equatable {
    case notPaired
    case paired
    case pairining
}

enum ChangeType: String, Codable {
    case insert
    case remove
}

struct SDiff: Codable {
    var item: ShortcutObject, from: Int?, to: Int?
}

struct DeviceName: Codable {
    let name: String
}

class ConnectionManager: NSObject, ObservableObject {
    @Published var screenIndex = 0
    @Published var inProgressWindow: NSWindow?
    @Published var availablePeer: MCPeerID?
    @Published var availablePeerWithName: (MCPeerID?, String)?
    @Published var connectedPeerName: String?
    @Published var connectedPeerResolution: String?
    @Published var receivedInvite: Bool = false
    @Published var receivedInviteFrom: MCPeerID?
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var selectedWorkspace: WorkspaceControl?
    @Published var pairingStatus: PairingStatus = .notPaired
    @Published var initialSetup: SetupMode?
    @Published var automatedActions: [AutomationOption]?
    @Published var websites: [WebsiteTest] = []
    @Published var createMultiactions: Bool?
    @Published var browser: Browsers?
    @Published var showsLocalError: Bool = false
    @Published var localError: String?
    @Published var dynamicUrls: (Browsers, [String]) = (.chrome, [])
    @Published var bitrate: CGFloat? = 1
    @Published var streamConnectionState: StreamConnectionState = .notConnected
    @Published var displayID: CGDirectDisplayID?
    private let tcpServer = TCPServerStreamer()
    let keyRecorder = KeyRecorder()
    private var cancellables = Set<AnyCancellable>()
    public var currentIndex = 0
    public let serviceType = "magic-trackpad"
    public var myPeerId: MCPeerID = {
        return MCPeerID(displayName: Host.current().name ?? "")
    }()
    private var keepAliveActivity: NSObjectProtocol?
    private var assertionID: IOPMAssertionID = 0
    
    public let serviceAdvertiser: MCNearbyServiceAdvertiser
    public let serviceBrowser: MCNearbyServiceBrowser
    public let session: MCSession
    public let log = Logger()
    public var runningApps: [RunningAppData] = []

    public var workspaces: [WorkspaceItem] = [] {
        didSet {
            self.send(workspaces: workspaces)
        }
    }
    public var shortcuts: [ShortcutObject] = [] {
        didSet {
            let diff = shortcuts.difference(from: oldValue)
            self.send(shortcutsDiff: handleDiff(diff))
        }
    }
    func handleDiff(_ diff: CollectionDifference<ShortcutObject>) -> [ChangeType: [SDiff]] {
        var insertedItems: [SDiff] = []
        var removedItems: [SDiff] = []

        for change in diff {
            switch change {
            case let .insert(_, element, associatedWith):
                if let fromIndex = associatedWith {
                } else {
                    // This is a new insert
                    insertedItems.append(.init(item: element, from: nil, to: nil))
                }

            case let .remove(_, element, associatedWith):
                if associatedWith == nil {
                    // This is a real removal
                    removedItems.append(.init(item: element, from: nil, to: nil))
                }
                // If it's part of a move, we already handled it on insert side
            }
        }
        return [ChangeType.insert: insertedItems, ChangeType.remove: removedItems]
    }
    public var observers = [NSKeyValueObservation]()
    public var subscriptions = Set<AnyCancellable>()
    public var isUpdating = false
    public var isConnecting: Bool {
        availablePeer != nil && pairingStatus == .notPaired
    }
    private var deviceName: String {
        Host.current().localizedName ?? ""
    }

    public var cursorPosition: CGPoint = .zero
    private var uuidCode: String?
    
    var iosDevice: iOSDevice? {
        guard let connectedPeerName else { return nil }
        let test = connectedPeerResolution?.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap { CGFloat(Double($0) ?? 0) }
        let resolution: CGSize = .init(width: test?[0] ?? 0.0, height: test?[1] ?? 0.0)
        return connectedPeerName.contains("iPad") ? .init(type: .ipad, resolution: resolution) : .init(type: .iphone, resolution: resolution)
    }
    
    override init() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: ["name": Host.current().localizedName ?? ""], serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        super.init()

        runningApps = getRunningApps()
        workspaces = UserDefaults.standard.get(key: .workspaceItems) ?? []
        shortcuts = UserDefaults.standard.get(key: .shortcuts) ?? []

        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        startAdvertising()
        startBrowsing()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleData(_:)),
            name: .extendScreen,
            object: nil
        )
    }
    
    @objc private func handleData(_ notification: Notification) {
        extendScreen()
    }
    
    func extendScreen() {
        Task { @MainActor in
            streamConnectionState = .connecting
            await startTCPServer { success, displayId in
                if let displayId {
                    self.displayID = displayId
                } else {
                    self.streamConnectionState = .notConnected
                }
            } streamConnection: { connected in
                if connected {
                    self.streamConnectionState = .connected
                } else {
                    self.streamConnectionState = .notConnected
                }
            }
        }
    }
    
    func startTCPServer(
        completion: @escaping(Bool, CGDirectDisplayID?) -> Void,
        streamConnection: @escaping (Bool) -> Void
    ) async {
        guard let iosDevice else {
            completion(false, nil)
            return
        }
        
        await tcpServer.startServer(
            bitrate: .init(
                get: { self.bitrate },
                set: { newValue in self.bitrate = newValue ?? 1.0 }),
            device: iosDevice
        ) { [weak self] success, displayId in
            if success, let ipAddress = self?.getLocalIPAddress() {
                self?.sendStartStream(action: "START", ipAddress: ipAddress)
            }
            DispatchQueue.main.async {
                completion(success, displayId)
            }
        } streamConnection: { connected in
            DispatchQueue.main.async {
                streamConnection(connected)
            }
        }
    }
    
    func stopTCPServer(completion: @escaping(Bool) -> Void) {
        tcpServer.stopServer { [weak self] in
            self?.sendStartStream(action: "STOP", ipAddress: "")
            completion(true)
        }
    }
    
    func generateUUID() -> String {
        let code = UUID().uuidString
        self.uuidCode = code
        return code
    }
    
    func isValidUUID(_ code: String) -> Bool {
        guard let uuidCode else { return false }
        return uuidCode == code
    }
    
    deinit {
        stopAdvertising()
        stopBrowsing()
    }
    
    func startAdvertising() {
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    func stopAdvertising() {
        serviceAdvertiser.stopAdvertisingPeer()
    }
    
    func startBrowsing() {
        serviceBrowser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        serviceBrowser.stopBrowsingForPeers()
        availablePeer = nil
    }
    
    func toggleAdvertising() {
        switch pairingStatus {
        case .notPaired:
            startAdvertising()
            stopKeepAliveActivity()
            allowSleep()
        case .pairining:
            break
        case .paired:
            stopAdvertising()
            startKeepAliveActivity()
            preventSleep()
        }
    }
    
    func invitePeer(with peer: MCPeerID, context: Data? = nil) {
        let name = try? JSONEncoder().encode(DeviceName(name: deviceName))
        serviceBrowser.invitePeer(peer, to: session, withContext: name, timeout: 30)
    }
    
    func cancel() {
        serviceBrowser.stopBrowsingForPeers()
        pairingStatus = .notPaired
    }
    
    func disconnect() {
        session.disconnect()
        pairingStatus = .notPaired
        toggleAdvertising()
    }
    
    func preventSleep() {
        let reasonForActivity = "TCP + Multipeer streaming requires continuous processing" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reasonForActivity,
            &assertionID
        )
        
        if result == kIOReturnSuccess {
            print("Sleep prevention assertion created.")
        }
    }

    func allowSleep() {
        IOPMAssertionRelease(assertionID)
        print("Sleep prevention assertion released.")
    }

    func startKeepAliveActivity() {
        keepAliveActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .latencyCritical, .idleSystemSleepDisabled, .suddenTerminationDisabled, .automaticTerminationDisabled],
            reason: "Screen streaming and multipeer connection"
        )
    }

    func stopKeepAliveActivity() {
        if let activity = keepAliveActivity {
            ProcessInfo.processInfo.endActivity(activity)
            keepAliveActivity = nil
        }
    }
}

struct ConnectionRequest: Codable {
    let shouldConnect: Bool
}

extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if let context, let data = String(data: context, encoding: .utf8), isValidUUID(data) {
            connectedPeerName = availablePeerWithName?.1
            invitationHandler(true, session)
            _ = generateUUID()
        } else if let context, let connectionRequest = try? JSONDecoder().decode(ConnectionRequest.self, from: context) {
            invitationHandler(connectionRequest.shouldConnect, session)
        } else {
            invitationHandler(false, nil)
        }
    }
}

extension ConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            if self.availablePeer == nil, !peerID.displayName.contains(".local") {
                let name = info?["name"] ?? peerID.displayName
                self.availablePeerWithName = (peerID, name)
                self.connectedPeerName = name
                self.connectedPeerResolution = info?["screenResolution"]
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard availablePeer == peerID else { return }
        availablePeer = nil
    }
}

extension ConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.pairingStatus = state == .connected ? .paired : .notPaired
            if state == .notConnected {
                self.stopTCPServer { _ in
//                    self.streamConnectionState = .notConnected
                }
            }
            self.toggleAdvertising()
        }
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log.error("Receiving streams is not supported")
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.error("Receiving resources is not supported")
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.error("Receiving resources is not supported")
    }
}

extension Notification.Name {
    static let extendScreen = Notification.Name("extendScreen")
}
