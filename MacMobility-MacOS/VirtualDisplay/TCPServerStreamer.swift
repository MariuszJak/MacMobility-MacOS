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
    private var listener: NWListener?
    private var connection: NWConnection?
    private var stream: SCStream?
    private let queue = DispatchQueue(label: "ScreenStreamQueue")
    private let ciContext = CIContext()
    private var isConnected = false
    private let screenViewManager = ScreenViewManager()
    private var iosDevice: iOSDevice?
    
    func startServer(
        device: iOSDevice,
        completion: @escaping (Bool, CGDirectDisplayID?) -> Void,
        streamConnection: @escaping (Bool) -> Void
    ) async {
        self.iosDevice = device
        do {
            let displayId = screenViewManager.createScreen(for: device)
            guard let display = try await scDisplay(for: displayId) else { return }
            let config = SCStreamConfiguration()
            config.width = Int(device.resolutions.width)
            config.height = Int(device.resolutions.height)
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.minimumFrameInterval = CMTime(value: 1, timescale: 30)

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
            streamConnection(true)
        }
        listener?.start(queue: .global())
        print("Server listening on port 8888")
    }

    private func sendImageData(_ data: Data) {
        guard isConnected, let connection = connection else { return }

        var length = UInt32(data.count).bigEndian
        let lengthData = Data(bytes: &length, count: 4)

        connection.send(content: lengthData + data, completion: .contentProcessed({ error in
            if let error = error {
                self.isConnected = false
            }
        }))
    }

    private func compressToJPEG(from buffer: CVPixelBuffer) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: iosDevice?.compression ?? 0.5])
    }
}

extension TCPServerStreamer: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        if let jpegData = compressToJPEG(from: pixelBuffer) {
            sendImageData(jpegData)
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
