//
//  ScreenViewManager.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 15/05/2025.
//

import Foundation

struct iOSDevice {
    let type: iOSDeviceType
    var resolution: CGSize
}

enum iOSDeviceType {
    case ipad
    case iphone
}

class ScreenViewManager {
    private var display: CGVirtualDisplay!
    private var stream: CGDisplayStream?
    private var isWindowHighlighted = false
    private var previousResolution: CGSize?
    private var previousScaleFactor: CGFloat?
    
    func createScreen(for device: iOSDevice) -> CGDirectDisplayID {
        let descriptor = CGVirtualDisplayDescriptor()
        descriptor.setDispatchQueue(DispatchQueue.main)
        descriptor.name = "MacMobility Display"
        descriptor.maxPixelsWide = 3840
        descriptor.maxPixelsHigh = 2160
        descriptor.sizeInMillimeters = CGSize(width: 1600, height: 1000)
        descriptor.productID = 0x1234
        descriptor.vendorID = 0x3456
        descriptor.serialNum = 0x0001
        
        let display = CGVirtualDisplay(descriptor: descriptor)
        self.display = display
        
        let settings = CGVirtualDisplaySettings()
        settings.hiDPI = 1
        settings.modes = [
            CGVirtualDisplayMode(width: UInt(device.resolution.width), height: UInt(device.resolution.height), refreshRate: 60),
        ]
        display.apply(settings)
        return display.displayID
    }
    
    func terminateScreen() {
        display = nil
    }
}
