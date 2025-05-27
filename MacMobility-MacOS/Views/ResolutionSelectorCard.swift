//
//  ResolutionSelectorCard.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 17/05/2025.
//

import Foundation
import SwiftUI

struct ResolutionSelectorCard: View {
    let displayID: CGDirectDisplayID
    let iosDevice: iOSDevice
    @State private var resolutions: [DisplayMode] = []
    @State private var bitrates: [CGFloat] = [1, 2, 3, 4, 5, 6, 7]
    let descriptions: [CGFloat: String] = [
        1: "1 bits per pixel",
        2: "2 bits per pixel",
        3: "3 bits per pixel",
        4: "4 bits per pixel",
        5: "5 bits per pixel",
        6: "6 bits per pixel",
        7: "7 bits per pixel"
    ]
    @State private var selectedMode: DisplayMode?
    @Binding var bitrate: CGFloat?
    
    init(displayID: CGDirectDisplayID, iosDevice: iOSDevice, bitrate: Binding<CGFloat?>) {
        self._bitrate = bitrate
        self.iosDevice = iosDevice
        self.displayID = displayID
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "display")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 8) {
//                Picker("Bitrate", selection: $bitrate) {
//                    ForEach(bitrates, id: \.self) { bitrate in
//                        Text(descriptions[bitrate] ?? "-").tag(Optional(bitrate))
//                    }
//                }
//                .pickerStyle(MenuPickerStyle())
                Text("Resolution: \(selectedMode?.description ?? "")")
                
                Button("Open Display Settings") {
                    openDisplayArrangementSettings()
                }
                .buttonStyle(LinkButtonStyle())
                Text("To rearrange displays, click the 'Arrange...' tab in System Settings.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
        )
        .padding()
        .onAppear {
            if let initialMode = getDisplayModeForResolution(iosDevice.resolution) {
                setDisplayResolution(displayID: displayID, to: initialMode.cgMode)
            }
            let all = getSupportedResolutions(for: displayID)
            if let current = CGDisplayCopyDisplayMode(displayID) {
                let aspectRatio = Double(current.width) / Double(current.height)
                resolutions = all.filter {
                    !$0.isScaled &&
                    abs((Double($0.width) / Double($0.height)) - aspectRatio) < 0.01
                }
                selectedMode = resolutions.first(where: { $0.cgMode == current })
            }
            
        }
    }
    
    private func openDisplayArrangementSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func getDisplayModeForResolution(_ resolution: CGSize) -> DisplayMode? {
        let all = getSupportedResolutions(for: displayID)
        return all.first(where: { $0.width == Int(resolution.width) && $0.height == Int(resolution.height) })
    }
    
    func getSupportedResolutions(for displayID: CGDirectDisplayID) -> [DisplayMode] {
        guard let modes = CGDisplayCopyAllDisplayModes(displayID, nil) as? [CGDisplayMode] else {
            return []
        }

        return modes.map { mode in
            let isScaled = mode.pixelWidth != mode.width || mode.pixelHeight != mode.height
            return DisplayMode(
                cgMode: mode,
                width: mode.width,
                height: mode.height,
                refreshRate: mode.refreshRate,
                isScaled: isScaled
            )
        }
    }

    func setDisplayResolution(displayID: CGDirectDisplayID, to mode: CGDisplayMode) {
        let config = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 1)
        defer { config.deallocate() }

        if CGBeginDisplayConfiguration(config) == .success {
            if CGConfigureDisplayWithDisplayMode(config.pointee, displayID, mode, nil) == .success {
                CGCompleteDisplayConfiguration(config.pointee, .permanently)
            } else {
                CGCancelDisplayConfiguration(config.pointee)
            }
        }
    }

    private func getCurrentDisplayMode(displayID: CGDirectDisplayID, from list: [DisplayMode]) -> DisplayMode? {
        guard let current = CGDisplayCopyDisplayMode(displayID) else { return nil }
        return list.first(where: { $0.cgMode == current })
    }
}
