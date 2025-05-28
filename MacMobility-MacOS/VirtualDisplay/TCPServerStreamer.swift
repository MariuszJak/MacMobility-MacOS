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

import Foundation
import ScreenCaptureKit
import AVFoundation
import VideoToolbox
import AppKit
import Combine

//@MainActor
class TCPServerStreamer: NSObject, ObservableObject, SCStreamDelegate, SCStreamOutput {
    private var lastFrameTime: CFTimeInterval = 0
    private let minimumFrameInterval: CFTimeInterval = 1.0 / 60.0
    private var stream: SCStream?
    private let streamQueue = DispatchQueue(label: "ScreenCaptureQueue")
    private var compressionSession: VTCompressionSession?
    private var cancellables = Set<AnyCancellable>()
    
    @Binding var bitrate: CGFloat?
    private var listener: NWListener?
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "ScreenStreamQueue")
    private let ciContext = CIContext()
    private var isConnected = false
    private let screenViewManager = ScreenViewManager()
    private var iosDevice: iOSDevice?
    private var isKeyPressed = false
    private var toggleShift = false
    var displayId: CGDirectDisplayID?
    let framerate = 60.0
    private var lastFrameChecksum: Int?

    override init() {
        self._bitrate = .constant(1.0)
        super.init()
        startKeyListener()
    }
    
    func startServer(
        bitrate: Binding<CGFloat?>,
        device: iOSDevice,
        completion: @escaping (Bool, CGDirectDisplayID?) -> Void,
        streamConnection: @escaping (Bool) -> Void
    ) async {
        self.iosDevice = device
        self._bitrate = bitrate
        do {
            let localId = screenViewManager.createScreen(for: device)
            displayId = localId
            guard let display = try await scDisplay(for: localId) else {
                completion(false, nil)
                return
            }
            let config = SCStreamConfiguration()
            config.width = Int(device.resolution.width)
            config.height = Int(device.resolution.height)
            config.pixelFormat = kCVPixelFormatType_32BGRA
            
            config.minimumFrameInterval = CMTime(value: 1, timescale: Int32(framerate))
            config.queueDepth = 3
            config.showsCursor = true

            let filter = SCContentFilter(display: display, excludingWindows: [])
            stream = SCStream(filter: filter, configuration: config, delegate: self)
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)

            try await stream?.startCapture()
            setupCompressionSession(width: Int(display.width), height: Int(display.height))
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

    func pixelBufferChecksum(_ buffer: CVPixelBuffer) -> Int {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)!
        
        var hash = 0
        for y in stride(from: 0, to: height, by: 10) {
            let row = baseAddress.advanced(by: y * bytesPerRow)
            for x in stride(from: 0, to: width * 4, by: 40) {
                hash = hash &+ Int(row.load(fromByteOffset: x, as: UInt32.self))
            }
        }
        return hash
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
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 60
        
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.serviceClass = .interactiveVideo
        
        listener = try NWListener(using: parameters, on: 8888)
        listener?.newConnectionHandler = { [weak self] newConn in
            guard let self = self else { return }
            
            print("Accepted new connection from \(newConn.endpoint)")
            self.connection = newConn
            
            newConn.betterPathUpdateHandler = { hasBetterPath in
                if hasBetterPath {
                    print("Better network path available - optimizing connection")
                }
            }
            
            newConn.start(queue: self.queue)
            self.isConnected = true
            self.continueReceiving(on: newConn)
            streamConnection(true)
        }
        
        listener?.start(queue: self.queue)
        print("Server listening on port 8888")
    }
    
    private func setupCompressionSession(width: Int, height: Int) {
        // Request hardware acceleration for encoding
        let encoderSpecification: [String: Any] = [
            kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder as String: true,
            kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder as String: true
        ]
        
        // Create pixel buffer attributes optimized for performance
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        VTCompressionSessionCreate(
            allocator: nil,
            width: Int32(width),
            height: Int32(height),
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: encoderSpecification as CFDictionary,
            imageBufferAttributes: pixelBufferAttributes as CFDictionary,
            compressedDataAllocator: nil,
            outputCallback: Self.compressionOutputCallback,
            refcon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            compressionSessionOut: &compressionSession
        )
        
        guard let compressionSession = compressionSession else { return }
        
        // Optimize for real-time streaming
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
        
        // Set profile to High for better quality/compression tradeoff
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_High_AutoLevel)
        
        // Set bitrate - adjust based on screen resolution and desired quality
        let targetBitRate = Double(width) * Double(height) * 4.0 // Approx 2 bits per pixel
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_AverageBitRate, value: targetBitRate as CFNumber)
        
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: framerate as CFNumber)
        
        // More consistent quality with bitrate limits
        let dataRateLimit = width * height // 4 bits per pixel max
        let limits: [String: Any] = [
            kVTCompressionPropertyKey_DataRateLimits as String: [dataRateLimit / 8, 1] // bytes per second, 1 second window
        ]
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_DataRateLimits, value: limits as CFDictionary)
        
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: framerate as CFNumber)
                
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_MaxH264SliceBytes, value: 1024 * 100 as CFNumber)
        
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_PrioritizeEncodingSpeedOverQuality, value: kCFBooleanTrue)
        
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_MaxFrameDelayCount, value: 1 as CFNumber)
        
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_AllowTemporalCompression, value: kCFBooleanTrue)

        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_H264EntropyMode, value: kVTH264EntropyMode_CABAC)

    
        // Increase quality for static content
        VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_Quality, value: 0.8 as CFNumber)
                
        // Prepare the session for encoding
        VTCompressionSessionPrepareToEncodeFrames(compressionSession)
    }
    
    static let compressionOutputCallback: VTCompressionOutputCallback = { (
        outputCallbackRefCon,
        sourceFrameRefCon,
        status,
        infoFlags,
        sampleBuffer
    ) in
        guard status == noErr,
              let sampleBuffer = sampleBuffer,
              let refCon = outputCallbackRefCon else { return }

        let mySelf = Unmanaged<TCPServerStreamer>.fromOpaque(refCon).takeUnretainedValue()
        
        // Check if we have an active connection before processing
        guard mySelf.isConnected, mySelf.connection != nil else { return }

        // Process the frame right away to avoid Sendable issues
        // Check if it's a keyframe
        var isKeyFrame = false
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) {
            if CFArrayGetCount(attachments) > 0 {
                let dict = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFDictionary.self)
                let notSync = CFDictionaryContainsKey(dict, Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque())
                isKeyFrame = !notSync
            }
        }

        // Send SPS & PPS if it's a keyframe
        if isKeyFrame,
           let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) {

            var spsPointer: UnsafePointer<UInt8>?
            var spsSize: Int = 0
            var ppsPointer: UnsafePointer<UInt8>?
            var ppsSize: Int = 0
            var parameterSetCount: Int = 0
            
            // Get parameter set count
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                formatDesc, parameterSetIndex: 0,
                parameterSetPointerOut: nil, parameterSetSizeOut: nil,
                parameterSetCountOut: &parameterSetCount, nalUnitHeaderLengthOut: nil
            )
            
            guard parameterSetCount >= 2 else {
                print("Error: Expected at least 2 parameter sets, found \(parameterSetCount)")
                return
            }

            // Get SPS
            let spsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                formatDesc, parameterSetIndex: 0,
                parameterSetPointerOut: &spsPointer, parameterSetSizeOut: &spsSize,
                parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil
            )
            
            // Get PPS
            let ppsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                formatDesc, parameterSetIndex: 1,
                parameterSetPointerOut: &ppsPointer, parameterSetSizeOut: &ppsSize,
                parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil
            )
            
            // Check for errors
            guard spsStatus == noErr, ppsStatus == noErr else {
                print("Error retrieving SPS/PPS: SPS status \(spsStatus), PPS status \(ppsStatus)")
                return
            }

            if let spsPointer = spsPointer, let ppsPointer = ppsPointer {
                let nalStartCode: [UInt8] = [0x00, 0x00, 0x00, 0x01]
                let sps = Data(nalStartCode) + Data(bytes: spsPointer, count: spsSize)
                let pps = Data(nalStartCode) + Data(bytes: ppsPointer, count: ppsSize)
                
                // Send SPS followed by PPS as a single packet if possible
                let combinedPacket = sps + pps
                DispatchQueue.global(qos: .userInitiated).async {
                    mySelf.send(data: combinedPacket)
                }
            }
        }

        // Send actual encoded frame
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        var length = 0
        var totalLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?

        let result = CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: &length,
            totalLengthOut: &totalLength,
            dataPointerOut: &dataPointer
        )

        if result == kCMBlockBufferNoErr, let dataPointer = dataPointer {
            var currentOffset = 0
            let nalStartCode: [UInt8] = [0x00, 0x00, 0x00, 0x01]
            var outData = Data(capacity: totalLength + 128)

            while currentOffset < totalLength {
                var nalUnitLength: UInt32 = 0
                memcpy(&nalUnitLength, dataPointer + currentOffset, 4)
                nalUnitLength = CFSwapInt32BigToHost(nalUnitLength)

                guard currentOffset + 4 + Int(nalUnitLength) <= totalLength else {
                    print("Invalid NAL unit length: \(nalUnitLength), currentOffset: \(currentOffset), totalLength: \(totalLength)")
                    return
                }
                outData.append(contentsOf: nalStartCode)
                outData.append(Data(bytes: dataPointer + currentOffset + 4, count: Int(nalUnitLength)))
                currentOffset += 4 + Int(nalUnitLength)
            }

            let finalData = outData
            DispatchQueue.global(qos: .userInitiated).async {
                mySelf.send(data: finalData)
            }
        }
    }
    
    
    func startKeyListener() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.isKeyPressed = true
        }
    }
    
    func processCapturedBuffer(_ buffer: CVPixelBuffer, forceKeyframe: @escaping (Bool) -> Void) -> CVPixelBuffer {
        defer { isKeyPressed = false }

        if isKeyPressed {
            toggleShift.toggle()
            let shift = toggleShift ? CGPoint(x: 0.0, y: 0) : CGPoint(x: 0.0, y: 0)
            if let shifted = shiftedPixelBuffer(from: buffer, shift: shift) {
                forceKeyframe(true)
                return shifted
            }
        }
        forceKeyframe(false)
        return buffer
    }
    
    func shiftedPixelBuffer(from buffer: CVPixelBuffer, shift: CGPoint) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)

        let overlayColor = CIColor.randomCIColor(alpha: 0.0001)
        let dot = CIImage(color: overlayColor).cropped(to: CGRect(x: CGFloat(CVPixelBufferGetWidth(buffer)) * 0.5, y: CGFloat(CVPixelBufferGetHeight(buffer)) * 0.5, width: 500, height: 500))
        
        let composited = dot.composited(over: ciImage)
        
        var newBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ] as CFDictionary
        
        CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, attrs, &newBuffer)
        
        if let newBuffer = newBuffer {
            ciContext.render(composited, to: newBuffer)
            return newBuffer
        }
        
        return nil
    }
    
    private func continueReceiving(on conn: NWConnection) {
        // Use higher maximum length to allow for larger control packets
        conn.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] lengthData, _, _, error in
            guard let self = self, error == nil,
                  let lengthData = lengthData,
                  lengthData.count == 4 else {
                print("Failed to receive packet length or connection error")
                return
            }
            
            // Extract the packet length, endian-aware
            let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            
            // Validate packet size to avoid excessive memory allocation
            guard length > 0, length < 1024 * 1024 else { // 1MB max packet size
                print("Invalid packet length: \(length)")
                self.continueReceiving(on: conn)
                return
            }
            
            // Receive the packet content
            conn.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { [weak self] data, _, _, error in
                guard let self = self, error == nil,
                      let data = data, !data.isEmpty else {
                    print("Failed to receive full packet")
                    self?.continueReceiving(on: conn)
                    return
                }
                
                // Process the data on a background queue to avoid blocking network operations
                DispatchQueue.global(qos: .userInitiated).async {
                    self.handleIncomingPacket(data)
                    
                    // Continue receiving on the same queue as the connection
                    DispatchQueue.main.async {
                        self.continueReceiving(on: conn)
                    }
                }
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
    
    func send(data: Data) {
        guard let connection = connection else { return }

        var combinedData = Data(capacity: data.count + 4)
        var length = UInt32(data.count).bigEndian
        combinedData.append(UnsafeBufferPointer(start: &length, count: 1))
        combinedData.append(data)
         
        connection.send(content: combinedData, completion: .contentProcessed({ error in
            if let error = error {
                print("Error sending data: \(error)")
            }
        }))
    }
}

extension TCPServerStreamer {
    // Mark as nonisolated to satisfy the protocol requirement in Swift 6
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {

        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - lastFrameTime
        guard elapsed >= minimumFrameInterval else { return }
        guard outputType == .screen,
              let pixelBuffer = sampleBuffer.imageBuffer,
              CMSampleBufferIsValid(sampleBuffer) else {
            return
        }

        let checksum = self.pixelBufferChecksum(pixelBuffer)
        if let last = self.lastFrameChecksum, last == checksum {
            return
        }
        
        Task { @MainActor in
            guard let compressionSession = self.compressionSession, self.isConnected else { return }
            
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let duration = CMSampleBufferGetDuration(sampleBuffer)
            
            let frameProperties: [String: Any] = [
                kVTEncodeFrameOptionKey_ForceKeyFrame as String: false
            ]
            
            let processedBuffer = processCapturedBuffer(pixelBuffer) { force in
                VTSessionSetProperty(compressionSession, key: kVTEncodeFrameOptionKey_ForceKeyFrame, value: kCFBooleanTrue)
                if force {
                    VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: 2.0 as CFNumber)
                } else {
                    VTSessionSetProperty(compressionSession, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: self.framerate as CFNumber)
                }
            }
            
            VTCompressionSessionEncodeFrame(compressionSession,
                                            imageBuffer: processedBuffer,
                                            presentationTimeStamp: pts,
                                            duration: duration,
                                            frameProperties: frameProperties as CFDictionary,
                                            sourceFrameRefcon: nil,
                                            infoFlagsOut: nil)
        }
    }
}

extension CIColor {
    static func randomCIColor(alpha: CGFloat = 1.0) -> CIColor {
        return CIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: alpha
        )
    }
}
