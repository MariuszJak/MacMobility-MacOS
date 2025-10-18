//
//  HotKeyManager.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 16/06/2025.
//

import Foundation
import Cocoa
import Carbon.HIToolbox
import SwiftUI

class HotKeyManager {
    static let shared = HotKeyManager()

    private var generalHotKeyRef: EventHotKeyRef?        // for Ctrl + Option + Space
    private var arrowHotKeyRefs: [EventHotKeyRef?] = []  // for arrows + Enter
    private var eventHandler: EventHandlerRef?

    // MARK: - Register general hotkey (Ctrl + Option + Space)
    func registerGeneralHotKey() {
        let keyCode: UInt32 = UInt32(kVK_Space)
        let modifiers: UInt32 = UInt32(controlKey | optionKey)

        let hotKeyID = EventHotKeyID(
            signature: OSType("HTK1".fourCharCodeValue),
            id: 1
        )

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &generalHotKeyRef
        )

        installHandlerIfNeeded()
    }

    func unregisterGeneralHotKey() {
        if let ref = generalHotKeyRef {
            UnregisterEventHotKey(ref)
            generalHotKeyRef = nil
        }
    }

    // MARK: - Register arrow + enter hotkeys
    func registerArrowAndEnterHotKeys() {
        let hotKeys: [(UInt32, String)] = [
            (UInt32(kVK_UpArrow), "UPAR"),
            (UInt32(kVK_DownArrow), "DNAR"),
            (UInt32(kVK_LeftArrow), "LFAR"),
            (UInt32(kVK_RightArrow), "RTAR"),
            (UInt32(kVK_Return), "ENTR")
        ]

        for (keyCode, signature) in hotKeys {
            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(
                signature: OSType(signature.fourCharCodeValue),
                id: UInt32(arrowHotKeyRefs.count + 10)
            )

            RegisterEventHotKey(
                keyCode,
                0, // no modifier
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            arrowHotKeyRefs.append(hotKeyRef)
        }

        installHandlerIfNeeded()
    }

    func unregisterArrowAndEnterHotKeys() {
        for ref in arrowHotKeyRefs {
            if let ref { UnregisterEventHotKey(ref) }
        }
        arrowHotKeyRefs.removeAll()
    }

    // MARK: - Event handler setup
    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetApplicationEventTarget(), hotKeyCallback, 1, &eventType, nil, &eventHandler)
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
    GetEventParameter(
        eventRef,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    DispatchQueue.main.async {
        switch hotKeyID.signature {
        case OSType("HTK1".fourCharCodeValue):
            HotKeyResponder.shared.triggered()
        case OSType("UPAR".fourCharCodeValue):
            HotKeyResponder.shared.arrowPressed(.up)
        case OSType("DNAR".fourCharCodeValue):
            HotKeyResponder.shared.arrowPressed(.down)
        case OSType("LFAR".fourCharCodeValue):
            HotKeyResponder.shared.arrowPressed(.left)
        case OSType("RTAR".fourCharCodeValue):
            HotKeyResponder.shared.arrowPressed(.right)
        case OSType("ENTR".fourCharCodeValue):
            HotKeyResponder.shared.enterPressed()
        default:
            break
        }
    }

    return noErr
}

class HotKeyResponder: ObservableObject {
    static let shared = HotKeyResponder()

    @Published var showWindow = false
    @Published var isEnterPressed = false
    @Published var lastArrow: ArrowKey?

    enum ArrowKey {
        case up, down, left, right
    }

    func triggered() {
        showWindow = true
    }

    func arrowPressed(_ arrow: ArrowKey) {
        lastArrow = arrow
    }

    func enterPressed() {
        isEnterPressed = true
    }
}
