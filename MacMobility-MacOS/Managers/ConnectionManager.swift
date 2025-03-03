//
//  ConnectionManager.swift
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

enum PairingStatus: Equatable {
    case notPaired
    case paired
    case pairining
}

class ConnectionManager: NSObject, ObservableObject {
    @Published var availablePeer: MCPeerID?
    @Published var connectedPeerName: String?
    @Published var receivedInvite: Bool = false
    @Published var receivedInviteFrom: MCPeerID?
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var selectedWorkspace: WorkspaceControl?
    @Published var pairingStatus: PairingStatus = .notPaired
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
    public var webpages: [WebpageItem] = [] {
        didSet {
            self.send(webpages: webpages)
        }
    }
    public var workspaces: [WorkspaceItem] = [] {
        didSet {
            self.send(workspaces: workspaces)
        }
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
        webpages = UserDefaults.standard.getWebItems() ?? []
        workspaces = UserDefaults.standard.getWorkspaceItems() ?? []
        subscribeForRunningApps()

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
    
    func disconnect() {
        session.disconnect()
        pairingStatus = .notPaired
        toggleAdvertising()
    }
}

extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if let context, let data = String(data: context, encoding: .utf8), isValidUUID(data) {
            connectedPeerName = availablePeer?.displayName
            invitationHandler(true, session)
            _ = generateUUID()
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
