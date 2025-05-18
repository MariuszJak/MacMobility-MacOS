//
//  VirtualDisplay.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 15/05/2025.
//

import Foundation
import Network
import ScreenCaptureKit
import CoreImage

//@MainActor
class TCPServerStreamer: NSObject, ObservableObject, SCStreamDelegate {
    @Binding var compressionRate: CGFloat?
    private var listener: NWListener?
    private var connection: NWConnection?
    private var stream: SCStream?
    private let queue = DispatchQueue(label: "ScreenStreamQueue")
    private let ciContext = CIContext()
    private var isConnected = false
    private let screenViewManager = ScreenViewManager()
    private var iosDevice: iOSDevice?
    var displayId: CGDirectDisplayID?
    
    override init() {
        self._compressionRate = .constant(0.1)
    }
    
    func startServer(
        compressionRate: Binding<CGFloat?>,
        device: iOSDevice,
        completion: @escaping (Bool, CGDirectDisplayID?) -> Void,
        streamConnection: @escaping (Bool) -> Void
    ) async {
        self.iosDevice = device
        self._compressionRate = compressionRate
        do {
            let localId = screenViewManager.createScreen(for: device)
            displayId = localId
            guard let display = try await scDisplay(for: localId) else { return }
            let config = SCStreamConfiguration()
            config.width = Int(device.resolution.width)
            config.height = Int(device.resolution.height)
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.minimumFrameInterval = CMTime(value: 1, timescale: 60)

            let filter = SCContentFilter(display: display, excludingWindows: [])
            stream = SCStream(filter: filter, configuration: config, delegate: self)
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)

            try await stream?.startCapture()

            try await startTCPListener(streamConnection: streamConnection)
            completion(true, displayId)
        } catch {
            completion(false, nil)
        }
    }
    
    func scDisplay(for displayID: CGDirectDisplayID) async throws -> SCDisplay? {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        return content.displays.first(where: { $0.displayID == displayID })
    }

    func stopServer(completion: @escaping() -> Void) {
        screenViewManager.terminateScreen()
        stream?.stopCapture()
        listener?.cancel()
        connection?.cancel()
        stream = nil
        listener = nil
        connection = nil
        completion()
    }

    private func startTCPListener(
        streamConnection: @escaping (Bool) -> Void
    ) async throws {
        listener = try NWListener(using: .tcp, on: 8888)

        listener?.newConnectionHandler = { [weak self] newConn in
            guard let self = self else { return }
            
            print("Accepted new connection from \(newConn.endpoint)")
            self.connection = newConn
            newConn.start(queue: .global())
            self.isConnected = true
            self.continueReceiving(on: newConn)
            streamConnection(true)
        }
        listener?.start(queue: .global())
        print("Server listening on port 8888")
    }
    
    private func continueReceiving(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] lengthData, _, _, _ in
            guard let self = self,
                  let lengthData = lengthData,
                  lengthData.count == 4 else {
                print("Failed to receive packet length")
                return
            }
            
            let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            
            conn.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { data, _, _, _ in
                guard let data = data else {
                    print("Failed to receive full packet")
                    return
                }
                
                self.handleIncomingPacket(data)
                self.continueReceiving(on: conn)
            }
        }
    }
    
    private func handleIncomingPacket(_ data: Data) {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            handleControlPacket(json)
        } else {
            print("Received unknown packet")
        }
    }
    
    private func handleControlPacket(_ json: [String: Any]) {
        switch json["type"] as? String {
        case "click":
            if let dx = json["dx"] as? CGFloat, let dy = json["dy"] as? CGFloat, let displayId {
                performClick(onDisplayId: displayId, atLocalPoint: .init(x: dx, y: dy), double: false)
            }
        case "doubleClick":
            if let dx = json["dx"] as? CGFloat, let dy = json["dy"] as? CGFloat, let displayId {
                performClick(onDisplayId: displayId, atLocalPoint: .init(x: dx, y: dy), double: true)
            }
        case "drag":
            if let dx = json["dx"] as? CGFloat, let dy = json["dy"] as? CGFloat, let displayId {
                simulateDrag(onDisplayId: displayId, atLocalPoint: .init(x: dx, y: dy))
            }
        case "selectAndDragStart":
            if let dx = json["dx"] as? CGFloat, let dy = json["dy"] as? CGFloat, let displayId {
                selectAndDragStart(onDisplayId: displayId, atLocalPoint: .init(x: dx, y: dy))
            }
        case "selectAndDragUpdate":
            if let dx = json["dx"] as? CGFloat, let dy = json["dy"] as? CGFloat, let displayId {
                selectAndDragUpdate(onDisplayId: displayId, atLocalPoint: .init(x: dx, y: dy))
            }
        case "selectAndDragEnd":
            if let dx = json["dx"] as? CGFloat, let dy = json["dy"] as? CGFloat, let displayId {
                selectAndDragEnd(onDisplayId: displayId, atLocalPoint: .init(x: dx, y: dy))
            }
        case "scroll":
            if let dx = json["dx"] as? CGFloat, let dy = json["dy"] as? CGFloat, let displayId {
                scroll(onDisplayId: displayId, atLocalPoint: .init(x: dx, y: dy))
            }
        default:
            break
        }
    }

    private func performClick(onDisplayId displayId: CGDirectDisplayID, atLocalPoint localPoint: CGPoint, double: Bool) {
        let displayBounds = CGDisplayBounds(displayId)
        
        let globalPoint = CGPoint(
            x: displayBounds.origin.x + localPoint.x,
            y: displayBounds.origin.y + localPoint.y
        )
        if double {
            let clickDown = CGEvent(mouseEventSource: nil,
                                    mouseType: .leftMouseDown,
                                    mouseCursorPosition: globalPoint,
                                    mouseButton: .left)

            let clickUp = CGEvent(mouseEventSource: nil,
                                  mouseType: .leftMouseUp,
                                  mouseCursorPosition: globalPoint,
                                  mouseButton: .left)

            clickDown?.setIntegerValueField(.mouseEventClickState, value: 2)
            clickUp?.setIntegerValueField(.mouseEventClickState, value: 2)

            clickDown?.post(tap: .cghidEventTap)
            clickUp?.post(tap: .cghidEventTap)
        } else {
            let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: globalPoint, mouseButton: .left)
            let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: globalPoint, mouseButton: .left)
            
            mouseDown?.post(tap: .cghidEventTap)
            mouseUp?.post(tap: .cghidEventTap)
        }
    }
    
    func simulateDrag(onDisplayId displayId: CGDirectDisplayID, atLocalPoint localPoint: CGPoint) {
        let displayBounds = CGDisplayBounds(displayId)
        
        let globalPoint = CGPoint(
            x: displayBounds.origin.x + localPoint.x,
            y: displayBounds.origin.y + localPoint.y
        )
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: globalPoint, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    func selectAndDragStart(onDisplayId displayId: CGDirectDisplayID, atLocalPoint localPoint: CGPoint) {
        let displayBounds = CGDisplayBounds(displayId)
        
        let globalPoint = CGPoint(
            x: displayBounds.origin.x + localPoint.x,
            y: displayBounds.origin.y + localPoint.y
        )
        
        let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: globalPoint, mouseButton: .left)
        mouseDown?.setIntegerValueField(.mouseEventClickState, value: 1)
        mouseDown?.post(tap: .cghidEventTap)
    }
    
    func selectAndDragUpdate(onDisplayId displayId: CGDirectDisplayID, atLocalPoint localPoint: CGPoint) {
        let displayBounds = CGDisplayBounds(displayId)
        
        let globalPoint = CGPoint(
            x: displayBounds.origin.x + localPoint.x,
            y: displayBounds.origin.y + localPoint.y
        )
        
        let mouseDrag = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: globalPoint, mouseButton: .left)
        mouseDrag?.post(tap: .cghidEventTap)
    }
    
    func selectAndDragEnd(onDisplayId displayId: CGDirectDisplayID, atLocalPoint localPoint: CGPoint) {
        let displayBounds = CGDisplayBounds(displayId)
        
        let globalPoint = CGPoint(
            x: displayBounds.origin.x + localPoint.x,
            y: displayBounds.origin.y + localPoint.y
        )
        
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: globalPoint, mouseButton: .left)
        mouseUp?.post(tap: .cghidEventTap)
    }
    
    func scroll(onDisplayId displayId: CGDirectDisplayID, atLocalPoint localPoint: CGPoint) {
        let scrollEvent = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 1,
            wheel1: Int32(localPoint.y / 10),
            wheel2: Int32(localPoint.x),
            wheel3: 0
        )
        scrollEvent?.post(tap: .cghidEventTap)
    }

    private func sendImageData(_ data: Data) {
        guard isConnected, let connection = connection else { return }

        var length = UInt32(data.count).bigEndian
        let lengthData = Data(bytes: &length, count: 4)

        connection.send(content: lengthData + data, completion: .contentProcessed({ error in
            if error != nil {
                self.isConnected = false
            }
        }))
    }

    private func compressToJPEG(from buffer: CVPixelBuffer) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionRate ?? 0.5])
    }
}

extension TCPServerStreamer: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        if let jpegData = self.compressToJPEG(from: pixelBuffer) {
            self.sendImageData(jpegData)
        }
    }
}

import SwiftUI
import CoreGraphics

struct DisplayMode: Identifiable, Equatable, Hashable {
    let id = UUID()
    let cgMode: CGDisplayMode
    let width: Int
    let height: Int
    let refreshRate: Double
    let isScaled: Bool

    var description: String {
        "\(width)x\(height)\(isScaled ? " (Scaled)" : "")\(refreshRate > 0 ? " @ \(Int(refreshRate))Hz" : "")"
    }
}
