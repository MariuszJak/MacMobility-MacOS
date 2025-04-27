//
//  KeyRecorder.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 27/04/2025.
//

import Combine
import Cocoa

struct RecordedKey: Identifiable {
    let id: String = UUID().uuidString
    let key: String
}

class KeyRecorder: ObservableObject {
    @Published var recordedKeys: [RecordedKey] = []
    @Published var isRecording = false

    private var monitor: Any?

    func startRecording() {
        recordedKeys.removeAll()
        isRecording = true

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyPress(event)
            return event
        }
    }

    func stopRecording() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        isRecording = false
    }

    private func handleKeyPress(_ event: NSEvent) {
        var keyDescription = ""

        if event.modifierFlags.contains(.shift) && event.charactersIgnoringModifiers?.lowercased() != "shift" {
            keyDescription += "Shift + "
        }
        if event.modifierFlags.contains(.control) {
            keyDescription += "Control + "
        }
        if event.modifierFlags.contains(.option) {
            keyDescription += "Option + "
        }
        if event.modifierFlags.contains(.command) {
            keyDescription += "Command + "
        }

        if let characters = event.charactersIgnoringModifiers {
            keyDescription += characters.uppercased()
        }

        recordedKeys.append(.init(key: keyDescription))
    }
}

import Quartz

extension KeyRecorder {
    func keyCodeForModifier(_ modifier: CGEventFlags) -> CGKeyCode? {
        switch modifier {
        case .maskShift:
            return 56 // Left Shift
        case .maskControl:
            return 59 // Left Control
        case .maskAlternate:
            return 58 // Left Option
        case .maskCommand:
            return 55 // Left Command
        default:
            return nil
        }
    }

    func playMacro() {
        guard !recordedKeys.isEmpty else { return }

        var modifiers: [CGEventFlags] = []
        var mainKey: (keyCode: CGKeyCode, flags: CGEventFlags)? = nil

        for key in recordedKeys {
            let components = key.key.components(separatedBy: " + ")
            let flags: CGEventFlags = []
            var keyChar: String?

            for comp in components {
                switch comp {
                case "Shift":
                    modifiers.append(.maskShift)
                case "Control":
                    modifiers.append(.maskControl)
                case "Option":
                    modifiers.append(.maskAlternate)
                case "Command":
                    modifiers.append(.maskCommand)
                default:
                    keyChar = comp
                }
            }

            if let keyChar = keyChar,
               let keyCode = keyCodeForCharacter(keyChar) {
                mainKey = (keyCode, flags)
            }
        }

        // 1. Press down modifiers one by one
        for modifier in modifiers {
            if let modKeyCode = keyCodeForModifier(modifier) {
                if let event = CGEvent(keyboardEventSource: nil, virtualKey: modKeyCode, keyDown: true) {
                    event.post(tap: .cghidEventTap)
                }
            }
        }

        usleep(20_000) // Tiny delay to stabilize (20ms)

        // 2. Press main key
        if let mainKey = mainKey {
            if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: mainKey.keyCode, keyDown: true) {
                keyDown.flags = CGEventFlags(rawValue: modifiers.reduce(0) { $0 | $1.rawValue })
                keyDown.post(tap: .cghidEventTap)
            }

            usleep(20_000) // Hold key a tiny bit

            if let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: mainKey.keyCode, keyDown: false) {
                keyUp.flags = CGEventFlags(rawValue: modifiers.reduce(0) { $0 | $1.rawValue })
                keyUp.post(tap: .cghidEventTap)
            }
        }

        // 3. Release modifiers one by one
        for modifier in modifiers {
            if let modKeyCode = keyCodeForModifier(modifier) {
                if let event = CGEvent(keyboardEventSource: nil, virtualKey: modKeyCode, keyDown: false) {
                    event.post(tap: .cghidEventTap)
                }
            }
        }
    }
}

func keyCodeForCharacter(_ character: String) -> CGKeyCode? {
    let keyMapping: [String: CGKeyCode] = [
        "A": 0,
        "S": 1,
        "D": 2,
        "F": 3,
        "H": 4,
        "G": 5,
        "Z": 6,
        "X": 7,
        "C": 8,
        "V": 9,
        "B": 11,
        "Q": 12,
        "W": 13,
        "E": 14,
        "R": 15,
        "Y": 16,
        "T": 17,
        "1": 18,
        "2": 19,
        "3": 20,
        "4": 21,
        "6": 22,
        "5": 23,
        "=": 24,
        "9": 25,
        "7": 26,
        "-": 27,
        "8": 28,
        "0": 29,
        "]": 30,
        "O": 31,
        "U": 32,
        "[": 33,
        "I": 34,
        "P": 35,
        "L": 37,
        "J": 38,
        "'": 39,
        "K": 40,
        ";": 41,
        "\\": 42,
        ",": 43,
        "/": 44,
        "N": 45,
        "M": 46,
        ".": 47,
        "Return": 36,
        "Tab": 48,
        "Space": 49,
        "Delete": 51,
        "Escape": 53
        // Add more if needed
    ]
    
    return keyMapping[character]
}

