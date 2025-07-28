//
//  HotKeyManager.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 16/06/2025.
//

import Foundation
import Cocoa
import Carbon.HIToolbox

class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?

    func registerHotKey() {
        let keyCode: UInt32 = UInt32(kVK_Space)
        let modifiers: UInt32 = UInt32(controlKey | optionKey)

        let hotKeyID = EventHotKeyID(
            signature: OSType("HTK1".fourCharCodeValue),
            id: 1
        )

        // Register the hotkey globally
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        // Install the Carbon event handler once
        if eventHandler == nil {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                          eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), hotKeyCallback, 1, &eventType, nil, &eventHandler)
        }
    }

    func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }
}

extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        for char in utf16 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}

private var eventHandler: EventHandlerRef?

private let hotKeyCallback: EventHandlerUPP = { _, eventRef, _ in
    var hotKeyID = EventHotKeyID()
    GetEventParameter(eventRef, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

    if hotKeyID.signature == OSType("HTK1".fourCharCodeValue) {
        // Call your UI display function on main thread
        DispatchQueue.main.async {
            HotKeyResponder.shared.triggered()
        }
    }

    return noErr
}

import SwiftUI

class HotKeyResponder: ObservableObject {
    static let shared = HotKeyResponder()

    @Published var showWindow = false

    func triggered() {
        showWindow = true
    }
}
