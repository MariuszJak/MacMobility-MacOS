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
    @State private var compressionRates: [CGFloat] = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]
    let descriptions: [CGFloat: String] = [
        0.1: "90% (Low quality & fast performance)",
        0.2: "80%",
        0.3: "70%",
        0.4: "60% (Good quality & reliable performance)",
        0.5: "50%",
        0.6: "40%",
        0.7: "30% (High quality & low performance)",
        0.8: "20%",
        0.9: "10%",
        1.0: "0%"
    ]
    @State private var selectedMode: DisplayMode?
    @Binding var compressionRate: CGFloat?
    
    init(displayID: CGDirectDisplayID, iosDevice: iOSDevice, compressionRate: Binding<CGFloat?>) {
        self._compressionRate = compressionRate
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
                Picker("Compression", selection: $compressionRate) {
                    ForEach(compressionRates, id: \.self) { compressionRate in
                        Text(descriptions[compressionRate] ?? "-").tag(Optional(compressionRate))
                    }
                }
                .pickerStyle(MenuPickerStyle())
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
