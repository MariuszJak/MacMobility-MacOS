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

class ConnectionManager: NSObject, ObservableObject {
    @Published var screenIndex = 0
    @Published var inProgressWindow: NSWindow?
    @Published var availablePeer: MCPeerID?
    @Published var connectedPeerName: String?
    @Published var receivedInvite: Bool = false
    @Published var receivedInviteFrom: MCPeerID?
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var selectedWorkspace: WorkspaceControl?
    @Published var pairingStatus: PairingStatus = .notPaired
    @Published var initialSetup: SetupMode?
    @Published var automatedActions: [AutomationOption]?
    @Published var website: WebsiteTest?
    private var cancellables = Set<AnyCancellable>()
    public var currentIndex = 0
    public let serviceType = "magic-trackpad"
    public var myPeerId: MCPeerID = {
        return MCPeerID(displayName: Host.current().name ?? "")
    }()
    
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

    public var cursorPosition: CGPoint = .zero
    private var uuidCode: String?
    
    override init() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
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
        case .pairining:
            break
        case .paired:
            stopAdvertising()
        }
    }
    
    func invitePeer(with peer: MCPeerID, context: Data? = nil) {
        serviceBrowser.invitePeer(peer, to: session, withContext: context, timeout: 30)
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
}

struct ConnectionRequest: Codable {
    let shouldConnect: Bool
}

extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if let context, let data = String(data: context, encoding: .utf8), isValidUUID(data) {
            connectedPeerName = availablePeer?.displayName
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
            if self.availablePeer == nil {
                self.availablePeer = peerID
                self.connectedPeerName = peerID.displayName
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
