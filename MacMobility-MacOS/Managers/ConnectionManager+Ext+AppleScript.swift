//
//  ConnectionManager+Ext+AppleScript.swift
//  MacMobility
//
//  Created by CoderBlocks on 22/07/2023.
//

import Foundation
import AppKit

extension ConnectionManager: AppleScriptCommandable {
    func switchToNextWorkspace() {
        let scriptString = """
        tell application "System Events"
            key code 124 using control down
        end tell
        """
        execute(scriptString)
    }

    func switchToPreviousWorkspace() {
        let scriptString = """
        tell application "System Events"
            key code 123 using control down
        end tell
        """
        execute(scriptString)
    }

    func focusToApp(_ name: String) {
        guard !name.isEmpty else {
            return
        }
        let scriptString = """
        tell application "\(name)" to activate
        """
        execute(scriptString)
    }
}

